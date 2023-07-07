// SPDX-License-Identifier: UNLICESNED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractStates.sol";
import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_ID_, _MAX_REFINANCES_} from "@lending-constants/LoanContractNumbers.sol";
import {_UINT256_MAX_} from "@universal-numbers/StdNumbers.sol";
import {_INACTIVE_LOAN_STATE_SELECTOR_, _EXPIRED_LOAN_SELECTOR_} from "@custom-errors/StdCodecErrors.sol";
import {_INVALID_ADDRESS_ERROR_ID_} from "@custom-errors/StdAccessErrors.sol";

import {LoanManager} from "@services/LoanManager.sol";
import {ILoanManager} from "@services-interfaces/ILoanManager.sol";
import {AnzaDebtStorefront} from "@storefronts/AnzaDebtStorefront.sol";
import {AnzaSponsorshipStorefront} from "@storefronts/AnzaSponsorshipStorefront.sol";
import {AnzaRefinanceStorefront} from "@storefronts/AnzaRefinanceStorefront.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {LoanCodecInit} from "@test-base/_LoanCodec/LoanCodec__test.sol";
import {DebtTermsUtils} from "@test-databases/DebtTerms__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";

contract LoanManagerHarness is LoanManager {
    constructor() LoanManager() {}

    function exposed__checkLoanGracePeriod(
        uint256 _debtId
    ) public view returns (bool) {
        return _checkLoanGracePeriod(_debtId);
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

    function exposed__updateLoanState(
        uint256 _debtId,
        uint8 _newLoanState
    ) public {
        _updateLoanState(_debtId, _newLoanState);
    }

    /* ----- DebtBook Expose Functions ----- */
    function exposed__writeDebt(
        address _collateralAddres,
        uint256 _collateralId
    ) public returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        return _writeDebt(_collateralAddres, _collateralId);
    }

    function exposed__appendDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) public returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        return _appendDebt(_collateralAddress, _collateralId);
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
        loanManagerHarness.grantRole(_TREASURER_, address(loanTreasurer));

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
        // TODO: Need to check if there are test cases missed by not using >=.
        vm.assume(_contractTerms.duration > _contractTerms.gracePeriod);

        // Commital must be no greater than 100%.
        _contractTerms.commital = uint8(bound(_contractTerms.commital, 0, 100));

        // Lender royalties must be no greater than 100%.
        _contractTerms.lenderRoyalties = uint8(
            bound(_contractTerms.lenderRoyalties, 0, 100)
        );
    }
}

contract LoanManagerUnitTest is LoanManagerInit {
    using AnzaTokenIndexer for uint256;

    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- LoanManager.maxRefinances() ---------- */
    /**
     * Test the max refinances constant.
     *
     * @dev Full pass if the max refinances function matches the expected
     * value.
     */
    function testLoanManager_MaxRefinances_Fuzz() public {
        assertEq(
            loanManagerHarness.maxRefinances(),
            _MAX_REFINANCES_,
            "0 :: maxRefinances should return the correct value."
        );
    }

    /* --------- LoanManager.setAnzaToken() -------- */
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
    function testLoanManager_SetAnzaToke_Fuzzn(
        address _caller,
        address _anzaToken
    ) public {
        // Clear role
        vm.startPrank(admin);
        loanManagerHarness.setAnzaToken(address(0));
        vm.stopPrank();

        // Test the caller of the setter function.
        vm.startPrank(_caller);
        try loanManagerHarness.setAnzaToken(_anzaToken) {
            assertEq(_caller, admin, "0 :: caller should be the admin.");
            assertEq(
                loanManagerHarness.anzaToken(),
                _anzaToken,
                "1 :: anzaToken should be set to the correct address."
            );
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
                assertEq(
                    loanManagerHarness.anzaToken(),
                    address(0),
                    "3 :: anzaToken should not be set."
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
        vm.startPrank(admin);

        loanManagerHarness.setAnzaToken(_anzaToken);

        assertEq(
            loanManagerHarness.anzaToken(),
            _anzaToken,
            "4 :: anzaToken should be set to the correct address."
        );

        vm.stopPrank();
    }

    /* --------- LoanManager.setCollateralVault() -------- */
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
    function testLoanManager_SetCollateralVault_Fuzz(
        address _caller,
        address _collateralVault
    ) public {
        // Clear role
        vm.startPrank(admin);
        loanManagerHarness.setCollateralVault(address(0));
        vm.stopPrank();

        // Test the caller of the setter function.
        vm.startPrank(_caller);
        try loanManagerHarness.setCollateralVault(_collateralVault) {
            assertEq(_caller, admin, "0 :: caller should be the admin.");
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
                    "1 :: access control standard failure expected."
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
        vm.startPrank(admin);

        loanManagerHarness.setCollateralVault(_collateralVault);

        assertEq(
            loanManagerHarness.collateralVault(),
            _collateralVault,
            "2 :: collateralVault should be set to the correct address."
        );

        vm.stopPrank();
    }

    /* --------- LoanManager.updateLoanState() -------- */
    /**
     * Fuzz test the update loan state function for basic functionality without
     * payoffs.
     *
     * @dev This function tests a standard lifecycle of the loan state from
     * transition of:
     * 1. Active Grace -> Active -> Default
     * 2. Active -> Default
     *
     * @param _now The time to warp to.
     * @param _debtId The debt id of the loan to test.
     * @param _contractTerms The contract terms of the loan to test.
     *
     * @dev Full pass if the loan state is updated as expected.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function _testLoanManager_UpdateLoanState(
        uint256 _now,
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public {
        if (_contractTerms.gracePeriod > 1) {
            vm.warp(_now + _contractTerms.gracePeriod / 2);
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "0 :: _testLoanManager_UpdateLoanState :: loan should be updated successfully."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "1 :: _testLoanManager_UpdateLoanState :: loan state should be active grace."
            );
        }

        // Update loan state with time progression past grace period.
        vm.warp(_now + _contractTerms.gracePeriod);
        assertEq(
            loanManagerHarness.updateLoanState(_debtId),
            _ACTIVE_STATE_,
            "2 :: _testLoanManager_UpdateLoanState :: loan should be updated successfully."
        );
        assertEq(
            loanManagerHarness.loanState(_debtId),
            _ACTIVE_STATE_,
            "3 :: _testLoanManager_UpdateLoanState :: loan state should be active."
        );

        // Update loan state with time progression past duration.
        vm.warp(_now + _contractTerms.gracePeriod + _contractTerms.duration);
        assertEq(
            loanManagerHarness.updateLoanState(_debtId),
            _DEFAULT_STATE_,
            "4 :: _testLoanManager_UpdateLoanState :: loan state should be updated."
        );
        assertEq(
            loanManagerHarness.loanState(_debtId),
            _DEFAULT_STATE_,
            "5 :: _testLoanManager_UpdateLoanState :: loan state should be default."
        );

        // Attempt to revert loan state back to active.
        vm.warp(_now);
        vm.expectRevert(_INACTIVE_LOAN_STATE_SELECTOR_);
        loanManagerHarness.updateLoanState(_debtId);
    }

    /**
     * Fuzz test the update loan state function.
     *
     * @dev This function tests a standard lifecycle of the loan state from
     * transition of:
     * 1. Active Grace -> Active -> Default
     * 2. Active -> Default
     *
     * @param _amount The amount of the loan payment.
     * @param _debtId The debt ID of the loan.
     * @param _contractTerms The contract terms of the loan.
     *
     * @dev Full pass if the loan state is updated as expected.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testLoanManager_UpdateLoanState_Fuzz(
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
        uint256 _lenderTokenId = _debtId.debtIdToLenderTokenId();
        anzaTokenHarness.exposed__mint(lender, _lenderTokenId, _amount);

        vm.startPrank(address(loanTreasurer));

        // Update loan state without time progression.
        if (_contractTerms.gracePeriod > 0) {
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "0 :: loan should be in an active grace state."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "1 :: loan state should be active grace."
            );
        } else {
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _ACTIVE_STATE_,
                "0 :: loan should be in an active state."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_STATE_,
                "2 :: loan state should be active."
            );
        }

        // Update loan state with time progression within grace period.
        _testLoanManager_UpdateLoanState(_now, _debtId, _contractTerms);

        vm.stopPrank();
    }

    /**
     * Fuzz test the update loan state function with payoffs.
     *
     * @dev This function tests a lifecycle of the loan state with payoffs
     * from transition of:
     * 1. Active Grace -> Active -> Default
     * 2. Active -> Default
     * 3. Active Grace -> Paid
     * 4. Active -> Paid
     *
     * @param _amount The amount of the loan payment.
     * @param _debtId The debt ID of the loan.
     * @param _partialPayoff The percentage of the loan to pay off.
     * @param _contractTerms The contract terms of the loan.
     *
     * @dev Full pass if the loan state is updated as expected.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testLoanManager_UpdateLoanState_Fuzz_PayoffActive(
        uint256 _amount,
        uint256 _debtId,
        uint8 _partialPayoff,
        ContractTerms memory _contractTerms
    ) public {
        _partialPayoff = uint8(bound(_partialPayoff, 0, 100));
        vm.assume(_amount > 0 && _amount <= (_UINT256_MAX_ / 100));
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint256 _amountPayoff = (_amount * _partialPayoff) / 100;

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
        uint256 _lenderTokenId = _debtId.debtIdToLenderTokenId();
        anzaTokenHarness.exposed__mint(lender, _lenderTokenId, _amount);

        vm.startPrank(address(loanTreasurer));

        // Update loan state without time progression.
        if (_contractTerms.gracePeriod > 0) {
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "0 :: loan should be in an active grace state."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "1 :: loan state should be active grace."
            );
        } else {
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _ACTIVE_STATE_,
                "0 :: loan should be in an active state."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_STATE_,
                "2 :: loan state should be active."
            );
        }

        // Conduct payoff
        anzaTokenHarness.burnLenderToken(_debtId, _amountPayoff);
        assertEq(
            anzaTokenHarness.totalSupply(_debtId.debtIdToLenderTokenId()),
            _amount - _amountPayoff,
            "3 :: lender token supply should be updated."
        );

        if (_partialPayoff != 100) {
            // Update loan state with time progression within grace period.
            _testLoanManager_UpdateLoanState(_now, _debtId, _contractTerms);
        } else {
            // If grace period is 0, then no time update occurs here.
            vm.warp(_now + _contractTerms.gracePeriod / 2);
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _PAID_STATE_,
                "4 :: loan should be updated successfully."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _PAID_STATE_,
                "5 :: loan state should be paid."
            );

            // Update loan state with time progression past grace period.
            vm.warp(_now + _contractTerms.gracePeriod);
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                type(uint8).max,
                "6 :: loan should be not be updated."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _PAID_STATE_,
                "7 :: loan state should be paid."
            );

            // Update loan state with time progression past duration.
            vm.warp(
                _now + _contractTerms.gracePeriod + _contractTerms.duration
            );
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                type(uint8).max,
                "8 :: loan state should not be updated."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _PAID_STATE_,
                "9 :: loan state should be paid."
            );

            // Attempt to revert loan state back to active.
            vm.warp(_now);
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                type(uint8).max,
                "10 :: loan state should not be updated."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _PAID_STATE_,
                "11 :: loan state should be paid."
            );
        }

        vm.stopPrank();
    }

    /**
     * Fuzz test the update loan state function with expired loans.
     *
     * @dev This function tests a lifecycle of a loan contract with expiration
     * from transition of:
     * 1. Active Grace -> Expired
     * 2. Active -> Expired
     *
     * @notice This function also performs a payoff after the loan has expired.
     * This should have no impact on the ability of a loan state transition.
     *
     * @param _amount The amount of the loan payment.
     * @param _debtId The debt ID of the loan.
     * @param _partialPayoff The percentage of the loan to pay off.
     * @param _contractTerms The contract terms of the loan.
     *
     * @dev Full pass if the loan state is updated as expected.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testLoanManager_UpdateLoanState_Fuzz_PayoffExpired(
        uint256 _amount,
        uint256 _debtId,
        uint8 _partialPayoff,
        ContractTerms memory _contractTerms
    ) public {
        _partialPayoff = uint8(bound(_partialPayoff, 0, 99));
        vm.assume(_amount > 0 && _amount <= (_UINT256_MAX_ / 100));
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint256 _amountPayoff = (_amount * _partialPayoff) / 100;

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
        uint256 _lenderTokenId = _debtId.debtIdToLenderTokenId();
        anzaTokenHarness.exposed__mint(lender, _lenderTokenId, _amount);

        vm.startPrank(address(loanTreasurer));

        // Update loan state without time progression.
        if (_contractTerms.gracePeriod > 0) {
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "0 :: loan should be in an active grace state."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_GRACE_STATE_,
                "1 :: loan state should be active grace."
            );
        } else {
            assertEq(
                loanManagerHarness.updateLoanState(_debtId),
                _ACTIVE_STATE_,
                "2 :: loan should be in an active state."
            );
            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_STATE_,
                "3 :: loan state should be active."
            );
        }

        // Conduct partial payoff
        anzaTokenHarness.burnLenderToken(_debtId, _amountPayoff);

        // Update loan state with time progression past duration.
        vm.warp(_now + _contractTerms.gracePeriod + _contractTerms.duration);
        assertEq(
            loanManagerHarness.updateLoanState(_debtId),
            _DEFAULT_STATE_,
            "4 :: loan state should be updated."
        );
        assertEq(
            loanManagerHarness.loanState(_debtId),
            _DEFAULT_STATE_,
            "5 :: loan state should be default."
        );

        // Attempt to revert loan state back to active.
        vm.warp(_now);
        vm.expectRevert(_INACTIVE_LOAN_STATE_SELECTOR_);
        loanManagerHarness.updateLoanState(_debtId);

        assertEq(
            loanManagerHarness.loanState(_debtId),
            _DEFAULT_STATE_,
            "7 :: loan state should be default."
        );

        // Conduct full payoff
        anzaTokenHarness.burnLenderToken(_debtId, _amount - _amountPayoff);

        // Attempt to revert loan state back to active.
        vm.expectRevert(_INACTIVE_LOAN_STATE_SELECTOR_);
        loanManagerHarness.updateLoanState(_debtId);

        assertEq(
            loanManagerHarness.loanState(_debtId),
            _DEFAULT_STATE_,
            "9 :: loan state should be default."
        );

        vm.stopPrank();
    }

    /* --------- LoanManager.verifyLoanActive() -------- */
    /**
     * Fuzz test the verify loan active function.
     *
     * @param _debtId The debt ID of the loan.
     * @param _newLoanState The new loan state to test.
     *
     * @dev Full pass if the loan state is updated as expected.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testLoanManager_VerifyLoanActive_Fuzz(
        uint256 _debtId,
        uint8 _newLoanState,
        ContractTerms memory _contractTerms
    ) public {
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint8 _oldLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        _newLoanState = uint8(bound(_newLoanState, 0, 0x0f));
        vm.assume(_newLoanState != _oldLoanState);
        bool _isActiveState = _newLoanState != _ACTIVE_GRACE_STATE_ ||
            _newLoanState != _ACTIVE_STATE_;

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

        loanManagerHarness.exposed__updateLoanState(_debtId, _newLoanState);

        try loanManagerHarness.verifyLoanActive(_debtId) {
            assertTrue(
                loanManagerHarness.loanState(_debtId) == _ACTIVE_GRACE_STATE_ ||
                    loanManagerHarness.loanState(_debtId) == _ACTIVE_STATE_,
                "0 :: loan state should be active."
            );
        } catch (bytes memory _err) {
            // Check if the updated loan state is illegal due to the current loan
            // state and the new loan state being the same.
            if (_isActiveState) {
                assertEq(
                    bytes4(_err),
                    _INACTIVE_LOAN_STATE_SELECTOR_,
                    "1 :: 'inactive loan state' failure expected."
                );
            }
        }
    }

    /* --------- LoanManager.verifyLoanNotExpired() -------- */
    /**
     * Fuzz test the verify loan not expired function.
     *
     * @param _debtId The debt ID of the loan.
     * @param _amount The amount of debt tokens to mint.
     * @param _newLoanState The new loan state to test.
     *
     * @dev Full pass if the loan state is updated as expected.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testLoanManager_VerifyLoanNotExpired_Fuzz(
        uint256 _debtId,
        uint256 _amount,
        uint8 _newLoanState,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        _newLoanState = uint8(bound(_newLoanState, 0, 0x0f));
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint8 _oldLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        vm.assume(_newLoanState != _oldLoanState);
        bool _isNotActiveState = _newLoanState != _ACTIVE_GRACE_STATE_ &&
            _newLoanState != _ACTIVE_STATE_;

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
        if (_amount > 0) {
            uint256 _lenderTokenId = _debtId.debtIdToLenderTokenId();
            anzaTokenHarness.exposed__mint(lender, _lenderTokenId, _amount);
        }

        loanManagerHarness.exposed__updateLoanState(_debtId, _newLoanState);

        loanManagerHarness.verifyLoanNotExpired(_debtId);
        assertTrue(
            _amount == 0 ||
                loanManagerHarness.loanClose(_debtId) > block.timestamp,
            "0 :: loan state should not be expired."
        );

        // Check time based loan expiry.
        vm.warp(_now + _contractTerms.duration + _contractTerms.gracePeriod);
        try loanManagerHarness.verifyLoanNotExpired(_debtId) {
            assertEq(_amount, 0, "1 :: loan debt balance should be 0.");
            return;
        } catch (bytes memory _err) {
            // Verify that the new loan state was a not active state.
            if (_isNotActiveState) {
                assertEq(
                    bytes4(_err),
                    _EXPIRED_LOAN_SELECTOR_,
                    "1 :: 'expired loan' failure expected."
                );
            }
        }

        // Burn all lender tokens.
        vm.startPrank(address(loanTreasurer));
        anzaTokenHarness.burnLenderToken(_debtId, _amount);
        vm.stopPrank();

        // Check amount based loan expiry.
        loanManagerHarness.verifyLoanNotExpired(_debtId);
        assertTrue(
            _amount == 0 ||
                loanManagerHarness.loanClose(_debtId) <= block.timestamp,
            "2 :: loan state should not be expired."
        );
    }

    /* --------- LoanManager.checkProposalActive() -------- */
    /**
     * Fuzz test the check proposal active function.
     *
     * @param _collateralAddress The address of the collateral token.
     * @param _collateralId The ID of the collateral token.
     * @param _collateralNonce The nonce of the collateral token to check.
     *
     * @dev Full pass if the collateral nonce availability is as expected.
     */
    function testLoanManager_CheckProposalActive_Fuzz(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce
    ) public {
        vm.assume(_collateralAddress != address(0));
        vm.assume(_collateralNonce <= type(uint8).max);
        uint256 _nextNonce = 1;

        // Use up the collateral nonces.
        if (_collateralNonce >= _nextNonce++) {
            assertTrue(
                loanManagerHarness.checkProposalActive(
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
                ),
                "0 :: collateral nonce expected to be available."
            );

            // Use up the collateral nonces up to the _collateralNonce.
            loanManagerHarness.exposed__writeDebt(
                _collateralAddress,
                _collateralId
            );

            for (;;) {
                if (_collateralNonce < _nextNonce) break;

                assertTrue(
                    loanManagerHarness.checkProposalActive(
                        _collateralAddress,
                        _collateralId,
                        _collateralNonce
                    ),
                    "1 :: collateral nonce expected to be available."
                );

                loanManagerHarness.exposed__appendDebt(
                    _collateralAddress,
                    _collateralId
                );

                ++_nextNonce;
            }
        }

        // Validate the collateral nonce is now unavailable.
        if (_collateralNonce != 0)
            assertEq(
                _collateralNonce,
                _nextNonce - 1,
                "2 :: collateral nonce should be expected nonce - 1."
            );

        assertFalse(
            loanManagerHarness.checkProposalActive(
                _collateralAddress,
                _collateralId,
                _collateralNonce
            ),
            "3 :: collateral nonce expected to be unavailable."
        );
    }

    /* --------- LoanManager.checkLoanActive() -------- */
    /**
     * Fuzz test the check loan active function.
     *
     * @param _debtId The ID of the debt to check.
     * @param _newLoanState The new loan state to set.
     *
     * @dev Full pass if the loan state is as expected.
     */
    function testLoanManager_CheckLoanActive_Fuzz(
        uint256 _debtId,
        uint8 _newLoanState,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        _newLoanState = uint8(bound(_newLoanState, 0, 0x0f));
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint8 _oldLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        vm.assume(_newLoanState != _oldLoanState);
        bool _isActiveState = _newLoanState == _ACTIVE_GRACE_STATE_ ||
            _newLoanState == _ACTIVE_STATE_;

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

        // Verify loan active.
        assertTrue(
            loanManagerHarness.checkLoanActive(_debtId),
            "0 :: loan should be active."
        );

        // Update loan state.
        loanManagerHarness.exposed__updateLoanState(_debtId, _newLoanState);

        // Check updated loan state
        assertEq(
            loanManagerHarness.checkLoanActive(_debtId),
            _isActiveState,
            "1 :: loan state should match expected state."
        );
    }

    /* --------- LoanManager.checkLoanDefault() -------- */
    /**
     * Fuzz test the check loan default function.
     *
     * @param _debtId The ID of the debt to check.
     * @param _newLoanState The new loan state to set.
     *
     * @dev Full pass if the loan state is as expected.
     */
    function testLoanManager_CheckLoanDefault_Fuzz(
        uint256 _debtId,
        uint8 _newLoanState,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        _newLoanState = uint8(bound(_newLoanState, 0, 0x0f));
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint8 _oldLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        vm.assume(_newLoanState != _oldLoanState);
        bool _isDefaultState = _newLoanState >= _DEFAULT_STATE_ &&
            _newLoanState <= _AWARDED_STATE_;

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

        // Verify loan active.
        assertFalse(
            loanManagerHarness.checkLoanDefault(_debtId),
            "0 :: loan should not be default."
        );

        // Update loan state.
        loanManagerHarness.exposed__updateLoanState(_debtId, _newLoanState);

        // Check updated loan state
        assertEq(
            loanManagerHarness.checkLoanDefault(_debtId),
            _isDefaultState,
            "1 :: loan state should match expected state."
        );
    }

    /* --------- LoanManager.checkLoanClosed() -------- */
    /**
     * Fuzz test the check loan closed function.
     *
     * @param _debtId The ID of the debt to check.
     * @param _newLoanState The new loan state to set.
     *
     * @dev Full pass if the loan state is as expected.
     */
    function testLoanManager_CheckLoanClosed_Fuzz(
        uint256 _debtId,
        uint8 _newLoanState,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        _newLoanState = uint8(bound(_newLoanState, 0, 0x0f));
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint8 _oldLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        vm.assume(_newLoanState != _oldLoanState);
        bool _isClosedState = _newLoanState >= _PAID_PENDING_STATE_;

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

        // Verify loan active.
        assertFalse(
            loanManagerHarness.checkLoanClosed(_debtId),
            "0 :: loan should not be closed."
        );

        // Update loan state.
        loanManagerHarness.exposed__updateLoanState(_debtId, _newLoanState);

        // Check updated loan state
        assertEq(
            loanManagerHarness.checkLoanClosed(_debtId),
            _isClosedState,
            "1 :: loan state should match expected state."
        );
    }

    /* --------- LoanManager.checkLoanExpired() -------- */
    /**
     * Fuzz test the check loan expired function.
     *
     * @param _debtId The debt ID of the loan.
     * @param _amount The amount of debt tokens to mint.
     *
     * @dev Full pass if the loan state is updated as expected.
     */
    function testLoanManager_CheckLoanExpired_Fuzz(
        uint256 _debtId,
        uint256 _amount,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        vm.assume(_amount > 0);
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
        uint256 _lenderTokenId = _debtId.debtIdToLenderTokenId();
        anzaTokenHarness.exposed__mint(lender, _lenderTokenId, _amount);

        assertFalse(
            loanManagerHarness.checkLoanExpired(_debtId),
            "0 :: loan state should not be expired."
        );

        // Check time based loan expiry.
        vm.warp(_now + _contractTerms.duration + _contractTerms.gracePeriod);
        assertTrue(
            loanManagerHarness.checkLoanExpired(_debtId),
            "1 :: loan state should be expired."
        );

        vm.warp(_now + _contractTerms.duration + _contractTerms.gracePeriod);
        assertTrue(
            loanManagerHarness.checkLoanExpired(_debtId),
            "1 :: loan state should be expired."
        );

        // Rever time back.
        vm.warp(_now);
        assertFalse(
            loanManagerHarness.checkLoanExpired(_debtId),
            "2 :: loan state should not be expired."
        );

        // Burn all lender tokens.
        vm.startPrank(address(loanTreasurer));
        anzaTokenHarness.burnLenderToken(_debtId, _amount);
        vm.stopPrank();

        assertFalse(
            loanManagerHarness.checkLoanExpired(_debtId),
            "3 :: loan should not be expired."
        );

        // Check time based loan expiry.
        vm.warp(_now + _contractTerms.duration + _contractTerms.gracePeriod);
        assertFalse(
            loanManagerHarness.checkLoanExpired(_debtId),
            "4 :: loan should not be expired."
        );
    }

    /* --------- LoanManager._checkLoanGracePeriod() -------- */
    /**
     * Fuzz test the check loan grace period function.
     *
     * @param _debtId The debt ID of the loan.
     *
     * @dev Full pass if the loan state is updated as expected.
     */
    function testLoanManager__CheckLoanGracePeriod_Fuzz(
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public {
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

        assertEq(
            loanManagerHarness.exposed__checkLoanGracePeriod(_debtId),
            _contractTerms.gracePeriod != 0,
            "0 :: loan state grace period incorrect."
        );

        if (_contractTerms.gracePeriod != 0) {
            vm.warp(_now + _contractTerms.gracePeriod - 1);
            assertTrue(
                loanManagerHarness.exposed__checkLoanGracePeriod(_debtId),
                "1 :: loan state grace period incorrect."
            );
        }

        vm.warp(_now + _contractTerms.gracePeriod + 1);
        assertFalse(
            loanManagerHarness.exposed__checkLoanGracePeriod(_debtId),
            "2 :: loan state should not be in grace period."
        );

        // Rever time back.
        vm.warp(_now);
        assertEq(
            loanManagerHarness.exposed__checkLoanGracePeriod(_debtId),
            _contractTerms.gracePeriod != 0,
            "3 :: loan state grace period incorrect."
        );
    }
}
