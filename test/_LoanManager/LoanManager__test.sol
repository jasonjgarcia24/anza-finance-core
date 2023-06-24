// SPDX-License-Identifier: UNLICESNED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractStates.sol";
import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_ID_, _MAX_REFINANCES_} from "@lending-constants/LoanContractNumbers.sol";
import {_INACTIVE_LOAN_STATE_SELECTOR_} from "@custom-errors/StdCodecErrors.sol";
import {_INVALID_ADDRESS_ERROR_ID_} from "@custom-errors/StdAccessErrors.sol";

import {LoanManager} from "@base/LoanManager.sol";
import {AnzaDebtStorefront} from "@base/storefronts/AnzaDebtStorefront.sol";
import {AnzaSponsorshipStorefront} from "@base/storefronts/AnzaSponsorshipStorefront.sol";
import {AnzaRefinanceStorefront} from "@base/storefronts/AnzaRefinanceStorefront.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {LoanCodecInit} from "@test-base/_LoanCodec/LoanCodec__test.sol";
import {DebtTermsUtils} from "@test-databases/DebtTerms__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";

contract LoanManagerHarness is LoanManager {
    constructor() LoanManager() {}

    function exposed__checkGracePeriod(
        uint256 _debtId
    ) public view returns (bool) {
        return _checkGracePeriod(_debtId);
    }

    /* ----- LoanCodec Expose Functions ----- */
    function exposed__setLoanAgreement(
        uint64 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) public {
        _setLoanAgreement(_now, _debtId, _activeLoanIndex, _contractTerms);
    }
}

abstract contract LoanManagerInit is Setup {
    LoanManagerHarness public loanManagerHarness;
    DebtTermsUtils public debtTermsUtils;
    AnzaTokenHarness public anzaTokenHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy DebtTermsUtils.
        debtTermsUtils = new DebtTermsUtils();

        // Deploy LoanManagerHarness.
        loanManagerHarness = new LoanManagerHarness();

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();

        // Set AnzaToken access control roles
        anzaTokenHarness.grantRole(
            _LOAN_CONTRACT_,
            address(loanManagerHarness)
        );
        anzaTokenHarness.grantRole(_TREASURER_, address(loanTreasurer));
        anzaTokenHarness.grantRole(
            _COLLATERAL_VAULT_,
            address(collateralVault)
        );

        // Set LoanContract access control roles
        loanManagerHarness.setAnzaToken(address(anzaTokenHarness));
        loanManagerHarness.setLoanTreasurer(address(loanTreasurer));

        // Set LoanTreasurey access control roles
        loanTreasurer.setAnzaToken(address(anzaTokenHarness));

        anzaDebtStorefront = new AnzaDebtStorefront(
            address(anzaTokenHarness),
            address(loanManagerHarness),
            address(loanTreasurer)
        );

        anzaSponsorshipStorefront = new AnzaSponsorshipStorefront(
            address(anzaTokenHarness),
            address(loanManagerHarness),
            address(loanTreasurer)
        );

        anzaRefinanceStorefront = new AnzaRefinanceStorefront(
            address(anzaTokenHarness),
            address(loanManagerHarness),
            address(loanTreasurer)
        );

        // Set harnessed DebtBook access control roles
        loanManagerHarness.setAnzaToken(address(anzaTokenHarness));

        vm.stopPrank();
    }

    function cleanContractTerms(
        ContractTerms memory _contractTerms
    ) public view {
        // Only allow valid fir intervals.
        vm.assume(
            _contractTerms.firInterval <= 8 || _contractTerms.firInterval == 14
        );

        // Duration must be greater than grace period.
        vm.assume(_contractTerms.duration > _contractTerms.gracePeriod);

        // Commital must be no greater than 100%.
        _contractTerms.commital = uint8(bound(_contractTerms.commital, 0, 100));

        // Lender royalties must be no greater than 100%.
        _contractTerms.lenderRoyalties = uint8(
            bound(_contractTerms.lenderRoyalties, 0, 100)
        );
    }
}

contract LoanManagerUtils is LoanManagerInit {
    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- LoanCodec.maxRefinances() ---------- */
    /**
     * Test the max refinances constant.
     *
     * @dev Full pass if the max refinances function matches the expected
     * value.
     */
    function testLoanManager__Fuzz_MaxRefinances() public {
        assertEq(
            loanManagerHarness.maxRefinances(),
            _MAX_REFINANCES_,
            "0 :: maxRefinances should return the correct value."
        );
    }

    /* --------- LoanCodec.setAnzaToken() -------- */
    /**
     * Fuzz test the anza token setter function.
     *
     * @param _caller The address of the caller to test.
     * @param _anzaToken The Anza Token address.
     *
     * @dev Full pass if the caller is the admin and the anza token is set to
     * the correct address.
     * @dev Full pass if the anza token is set to the correct address.
     * @dev Caught fail/pass if the function reverts with the expected error
     * message.
     */
    function testLoanManager__Fuzz_SetAnzaToken(
        address _caller,
        address _anzaToken
    ) public {
        assertEq(
            loanManagerHarness.anzaToken(),
            address(0),
            "0 :: anzaToken should be initialized to the zero address."
        );

        // Test the caller of the setter function.
        vm.startPrank(_caller);
        try loanManagerHarness.setAnzaToken(_anzaToken) {
            assertEq(_caller, admin, "1 :: caller should be the admin.");
            vm.stopPrank();
            return;
        } catch Error(string memory _errStr) {
            if (_caller != admin) {
                assertEq(
                    keccak256(abi.encodePacked(_errStr)),
                    keccak256(
                        abi.encodePacked(
                            getAccessControlFailMsg(_ADMIN_, _caller)
                        )
                    ),
                    "2 :: access control standard failure expected."
                );
            } else {
                unexpectedFail(
                    "not access control standard failure, should not fail.",
                    _errStr
                );
            }
        }
        vm.stopPrank();

        // Test the address used by the setter function.
        try loanManagerHarness.setAnzaToken(_anzaToken) {
            assertEq(
                loanManagerHarness.anzaToken(),
                _anzaToken,
                "1 :: anzaToken should be set to the correct address."
            );
        } catch (bytes memory _err) {
            if (_anzaToken == address(0)) {
                assertEq(
                    bytes4(_err),
                    _INVALID_ADDRESS_ERROR_ID_,
                    "2 :: Anza Token address cannot be the zero address."
                );
            } else {
                unexpectedFail(
                    "not 'invalid address selector failure' expected.",
                    _err
                );
            }
        }
    }

    /* --------- LoanCodec.setCollateralVault() -------- */
    /**
     * Fuzz test the collateral vault setter function.
     *
     * @param _caller The address of the caller to test.
     * @param _collateralVault The Collateral Vault address.
     *
     * @dev Full pass if the caller is the admin and the collateral vault
     * is set to the correct address.
     * @dev Full pass if the collateral vault is set to the correct address.
     * @dev Caught fail/pass if the function reverts with the expected error
     * message.
     */
    function testLoanManager__Fuzz_SetCollateralVault(
        address _caller,
        address _collateralVault
    ) public {
        assertEq(
            loanManagerHarness.collateralVault(),
            address(0),
            "0 :: collateralVault should be initialized to the zero address."
        );

        // Test the caller of the setter function.
        vm.startPrank(_caller);
        try loanManagerHarness.setCollateralVault(_collateralVault) {
            assertEq(_caller, admin, "1 :: caller should be the admin.");
            vm.stopPrank();
            return;
        } catch Error(string memory _errStr) {
            if (_caller != admin) {
                assertEq(
                    keccak256(abi.encodePacked(_errStr)),
                    keccak256(
                        abi.encodePacked(
                            getAccessControlFailMsg(_ADMIN_, _caller)
                        )
                    ),
                    "2 :: access control standard failure expected."
                );
            } else {
                unexpectedFail(
                    "not access control standard failure, should not fail.",
                    _errStr
                );
            }
        }
        vm.stopPrank();

        // Test the address used by the setter function.
        try loanManagerHarness.setCollateralVault(_collateralVault) {
            assertEq(
                loanManagerHarness.collateralVault(),
                _collateralVault,
                "3:: collateralVault should be set to the correct address."
            );
        } catch (bytes memory _err) {
            if (_collateralVault == address(0)) {
                assertEq(
                    bytes4(_err),
                    _INVALID_ADDRESS_ERROR_ID_,
                    "4 :: Collateral Vault address cannot be the zero address."
                );
            } else {
                unexpectedFail(
                    "not 'invalid address selector failure', should not fail.",
                    _err
                );
            }
        }
    }

    /* --------- LoanCodec.updateLoanState() -------- */
    // function testLoanContract__UpdateLoanState() public {
    //     uint256 _debtId = loanContract.totalDebts();

    //     // Expect to fail for access control
    //     vm.startPrank(admin);
    //     vm.expectRevert(bytes(getAccessControlFailMsg(_TREASURER_, admin)));
    //     loanContract.updateLoanState(_debtId);
    //     vm.stopPrank();

    //     // Loan state update should fail because there is no loan
    //     vm.deal(treasurer, 1 ether);
    //     vm.startPrank(address(loanTreasurer));
    //     vm.expectRevert(
    //         abi.encodeWithSelector(StdCodecErrors.InactiveLoanState.selector)
    //     );
    //     loanContract.updateLoanState(_debtId);
    //     vm.stopPrank();

    //     // Create loan contract
    //     uint256 _timeLoanCreated = block.timestamp;
    //     createLoanContract(collateralId);
    //     _debtId = loanContract.totalDebts();

    //     // Loan state should remain unchanged
    //     vm.startPrank(address(loanTreasurer));
    //     loanContract.updateLoanState(_debtId);
    //     assertEq(
    //         loanContract.loanState(_debtId),
    //         _ACTIVE_GRACE_STATE_,
    //         "0 :: Loan state should remain unchanged"
    //     );
    //     assertEq(
    //         loanContract.loanLastChecked(_debtId),
    //         _timeLoanCreated + _GRACE_PERIOD_,
    //         "1 :: Loan last checked time should remain the loan start time"
    //     );

    //     // Loan state should change to _ACTIVE_STATE_
    //     vm.warp(loanContract.loanStart(_debtId));
    //     vm.expectEmit(true, true, true, true, address(loanContract));
    //     emit LoanStateChanged(_debtId, _ACTIVE_STATE_, _ACTIVE_GRACE_STATE_);
    //     loanContract.updateLoanState(_debtId);
    //     assertEq(
    //         loanContract.loanState(_debtId),
    //         _ACTIVE_STATE_,
    //         "2 :: Loan state should change to _ACTIVE_STATE_"
    //     );
    //     assertEq(
    //         loanContract.loanLastChecked(_debtId),
    //         _timeLoanCreated + _GRACE_PERIOD_,
    //         "3 :: Loan last checked time should remain the loan start time"
    //     );

    //     // Loan state should remain _ACTIVE_
    //     vm.warp(loanContract.loanClose(_debtId) - 1);
    //     uint256 _now = block.timestamp;
    //     loanContract.updateLoanState(_debtId);
    //     assertEq(
    //         loanContract.loanState(_debtId),
    //         _ACTIVE_STATE_,
    //         "4 :: Loan state should remain _ACTIVE_"
    //     );
    //     assertEq(
    //         loanContract.loanLastChecked(_debtId),
    //         _now,
    //         "5 :: Loan last checked time should be updated to now"
    //     );

    //     // Loan state should change to _DEFAULT_STATE_
    //     vm.warp(loanContract.loanClose(_debtId));
    //     vm.expectEmit(true, true, true, true, address(loanContract));
    //     emit LoanStateChanged(_debtId, _DEFAULT_STATE_, _ACTIVE_STATE_);
    //     _now = block.timestamp;
    //     loanContract.updateLoanState(_debtId);
    //     assertEq(
    //         loanContract.loanState(_debtId),
    //         _DEFAULT_STATE_,
    //         "6 :: Loan state should change to _DEFAULT_STATE_"
    //     );
    //     assertEq(
    //         loanContract.loanLastChecked(_debtId),
    //         _now,
    //         "7 :: Loan last checked time should be updated to now"
    //     );
    //     vm.stopPrank();

    //     // Loan payoff
    //     createLoanContract(collateralId + 1);
    //     _debtId = loanContract.totalDebts();

    //     vm.deal(borrower, _PRINCIPAL_);
    //     vm.startPrank(borrower);
    //     vm.expectEmit(true, true, true, true, address(loanContract));
    //     emit LoanStateChanged(_debtId, _PAID_STATE_, _ACTIVE_GRACE_STATE_);
    //     uint256 _loanStart = loanContract.loanStart(_debtId);
    //     (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
    //         abi.encodeWithSignature("depositPayment(uint256)", _debtId)
    //     );
    //     assertTrue(_success, "Payment was unsuccessful");
    //     assertEq(
    //         loanContract.loanState(_debtId),
    //         _PAID_STATE_,
    //         "8 :: Loan state should be paid in full"
    //     );
    //     assertEq(
    //         loanContract.loanLastChecked(_debtId),
    //         _loanStart,
    //         "9 :: Loan last checked time should remain the loan start time"
    //     );
    //     vm.stopPrank();
    // }

    function testLoanContract__FuzzUpdateLoanState(
        uint256 _amount,
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_amount > 0);
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;

        // Pack and store the contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        loanManagerHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Setting the loan agreement updates the duration to account for the grace
        // period. We need to do that here too.
        _contractTerms.duration -= _contractTerms.gracePeriod;

        // Check the unpacked contract terms.
        debtTermsUtils.checkLoanTerms(
            address(loanManagerHarness),
            _debtId,
            _activeLoanIndex,
            _now,
            _contractTerms
        );

        // Mint debt tokens.
        uint256 _lenderTokenId = anzaTokenHarness.lenderTokenId(_debtId);
        anzaTokenHarness.exposed__mint(lender, _lenderTokenId, _amount);

        vm.startPrank(address(loanTreasurer));

        // Update loan state without time progression.
        assertTrue(
            loanManagerHarness.updateLoanState(_debtId),
            "0 :: loan should be in an active state."
        );

        if (_contractTerms.gracePeriod > 0) {
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "1 :: loan state should be active grace."
            );
        } else {
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_STATE_,
                "2 :: loan state should be active."
            );
        }

        // Update loan state with time progression within grace period.
        if (_contractTerms.gracePeriod > 1) {
            vm.warp(_now + _contractTerms.gracePeriod / 2);
            assertTrue(
                loanManagerHarness.updateLoanState(_debtId),
                "3 :: loan should be in an active state."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "4 :: loan state should be active grace."
            );
        }

        // Update loan state with time progression past grace period.
        vm.warp(_now + _contractTerms.gracePeriod);
        assertTrue(
            loanManagerHarness.updateLoanState(_debtId),
            "5 :: loan should be in an active state."
        );
        assertEq(
            loanManagerHarness.loanState(_debtId),
            _ACTIVE_STATE_,
            "6 :: loan state should be active."
        );

        // Update loan state with time progression past duration.
        vm.warp(_now + _contractTerms.gracePeriod + _contractTerms.duration);
        assertFalse(
            loanManagerHarness.updateLoanState(_debtId),
            "7 :: loan state should be in an expired state."
        );
        assertEq(
            loanManagerHarness.loanState(_debtId),
            _DEFAULT_STATE_,
            "8 :: loan state should be default."
        );

        vm.warp(_now);
        try loanManagerHarness.updateLoanState(_debtId) returns (
            bool
        ) {} catch (bytes memory _err) {
            assertEq(
                bytes4(_err),
                _INACTIVE_LOAN_STATE_SELECTOR_,
                "9 :: loan state update should fail."
            );
        }
        vm.stopPrank();
    }
}
