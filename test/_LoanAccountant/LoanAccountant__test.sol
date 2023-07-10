// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";

import "@lending-constants/LoanContractStates.sol";
import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_SECONDS_PER_24_MINUTES_RATIO_SCALED_} from "@lending-constants/LoanContractNumbers.sol";
import {_UINT64_MAX_, _UINT128_MAX_, _SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";
import {StdCodecErrors} from "@custom-errors/StdCodecErrors.sol";
import "@custom-errors/StdLoanErrors.sol";

import {LoanAccountant} from "@services/LoanAccountant.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";
import {InterestCalculator as Interest} from "@lending-libraries/InterestCalculator.sol";
import {TypeUtils} from "@base/libraries/TypeUtils.sol";

import "@test-databases/TestConstants__test.sol";
import {Setup} from "@test-base/Setup__test.sol";
import {LoanManagerHarness} from "@test-manager/LoanManager__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";

contract LoanAccountantHarness is LoanAccountant, StdAssertions {
    function exposed__updatePermitted() public view returns (bool) {
        return _updatePermitted();
    }

    function implementer_debtUpdater(
        uint256 _debtId
    ) public debtUpdater(_debtId) {}

    function implementer_updatePermittedLocker(
        uint256 _debtId
    ) public updatePermittedLocker(_debtId) {}

    function implementer_onlyActiveLoan(
        uint256 _debtId
    ) public onlyActiveLoan(_debtId) {}

    /* Abstract functions */
    function setAnzaToken(address _anzaTokenAddress) public override {
        _setAnzaToken(_anzaTokenAddress);
    }
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract LoanAccountantInit is Setup {
    LoanManagerHarness public loanManagerHarness;
    AnzaTokenHarness public anzaTokenHarness;
    LoanAccountantHarness public loanAccountantHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy LoanManagerHarness.
        loanManagerHarness = new LoanManagerHarness();

        // Deploy AnzaToken.
        anzaTokenHarness = new AnzaTokenHarness();

        // Deploy LoanAccountantHarness.
        loanAccountantHarness = new LoanAccountantHarness();

        // Set AnzaToken access control roles.
        anzaTokenHarness.grantRole(
            _LOAN_CONTRACT_,
            address(loanManagerHarness)
        );
        anzaTokenHarness.grantRole(_TREASURER_, address(loanAccountantHarness));

        // Set LoanManagerHarness access control roles.
        loanManagerHarness.setAnzaToken(address(anzaTokenHarness));
        loanManagerHarness.grantRole(
            _TREASURER_,
            address(loanAccountantHarness)
        );

        // Set LoanAccountantHarness access control roles.
        loanAccountantHarness.setAnzaToken(address(anzaTokenHarness));
        loanAccountantHarness.grantRole(
            _LOAN_CONTRACT_,
            address(loanManagerHarness)
        );

        vm.stopPrank();
    }
}

contract LoanAccountantUnitTest is LoanAccountantInit {
    using TypeUtils for uint256;
    using AnzaTokenIndexer for uint256;

    function _validateStateChangesWithoutTimeWarp(uint256 _debtId) internal {
        assertTrue(
            loanAccountantHarness.exposed__updatePermitted(),
            "0 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be true."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _DEFAULT_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertTrue(
            loanAccountantHarness.exposed__updatePermitted(),
            "1 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be true."
        );

        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _COLLECTION_STATE_
        );
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertTrue(
            loanAccountantHarness.exposed__updatePermitted(),
            "2 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be true."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _AUCTION_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertTrue(
            loanAccountantHarness.exposed__updatePermitted(),
            "3 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be true."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _AWARDED_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertTrue(
            loanAccountantHarness.exposed__updatePermitted(),
            "4 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be true."
        );

        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _PAID_PENDING_STATE_
        );
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "5 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _CLOSE_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "6 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _PAID_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "7 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _CLOSE_DEFAULT_STATE_
        );
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "8 :: _validateStateChangesWithoutTimeWarp :: update permitted expected to be false."
        );
    }

    /* ----------------- LoanAccountant.debtUpdater() ----------------- */
    /**
     * Fuzz test the debt updater modifier.
     */
    function testLoanAccountant_Fuzz_DebtUpdater(
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        // Clean contract terms.
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        try
            loanManagerHarness.exposed__validateLoanTerms(
                _packedContractTerms,
                block.timestamp.toUint64(),
                _contractTerms.principal
            )
        {} catch (bytes memory) {
            vm.assume(false);
        }

        // Initial update without any contract terms should revert.
        vm.startPrank(address(loanAccountantHarness));
        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_debtUpdater(_debtId);
        vm.stopPrank();

        // Add contract terms.
        uint256 _activeLoanIndex = 1;
        uint64 _now = uint64(block.timestamp);
        loanManagerHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Mint lender tokens.
        anzaTokenHarness.exposed__mint(
            lender,
            _debtId.debtIdToLenderTokenId(),
            _contractTerms.principal
        );

        uint256 _loanState = loanManagerHarness.loanState(_debtId);
        uint256 _loanLastChecked = loanManagerHarness.loanLastChecked(_debtId);

        // Test without time change.
        vm.startPrank(address(loanAccountantHarness));
        loanAccountantHarness.implementer_debtUpdater(_debtId);
        vm.stopPrank();

        assertEq(
            loanManagerHarness.loanState(_debtId),
            _loanState,
            "0 :: loan state should remain unchanged."
        );

        assertEq(
            loanManagerHarness.loanLastChecked(_debtId),
            _loanLastChecked,
            "0 :: loan last checked should remain unchanged."
        );

        if (_contractTerms.gracePeriod > 0) {
            vm.warp(_now + _contractTerms.gracePeriod);
            vm.startPrank(address(loanAccountantHarness));
            loanAccountantHarness.implementer_debtUpdater(_debtId);
            vm.stopPrank();

            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_STATE_,
                "1 :: loan state should be updated."
            );

            assertEq(
                loanManagerHarness.loanLastChecked(_debtId),
                _now + _contractTerms.gracePeriod,
                "1 :: loan last checked should be updated."
            );
        }

        vm.warp(_now + _contractTerms.gracePeriod + _contractTerms.duration);
        vm.startPrank(address(loanAccountantHarness));
        loanAccountantHarness.implementer_debtUpdater(_debtId);
        vm.stopPrank();
    }

    /**
     * Test the debt updater modifier.
     */
    function testLoanAccountant_DebtUpdater() public {
        uint256 _debtId = _MAX_DEBT_ID_;

        ContractTerms memory _contractTerms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commitalRatio: _COMMITAL_RATIO_,
            commitalPeriod: 0,
            principal: _PRINCIPAL_,
            gracePeriod: _GRACE_PERIOD_,
            duration: _DURATION_,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        // Clean contract terms.
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        loanManagerHarness.exposed__validateLoanTerms(
            _packedContractTerms,
            block.timestamp.toUint64(),
            _contractTerms.principal
        );

        // Initial update without any contract terms should revert.
        vm.startPrank(address(loanAccountantHarness));
        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_debtUpdater(_debtId);
        vm.stopPrank();

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "0 :: update permitted expected to be false."
        );

        // Add contract terms.
        uint256 _activeLoanIndex = 1;
        uint64 _now = uint64(block.timestamp);
        loanManagerHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Mint lender tokens.
        anzaTokenHarness.exposed__mint(
            lender,
            _debtId.debtIdToLenderTokenId(),
            _contractTerms.principal
        );

        uint256 _loanState = loanManagerHarness.loanState(_debtId);
        uint256 _loanLastChecked = loanManagerHarness.loanLastChecked(_debtId);

        // Test without time change.
        vm.startPrank(address(loanAccountantHarness));
        loanAccountantHarness.implementer_debtUpdater(_debtId);
        vm.stopPrank();

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "1 :: update permitted expected to be false."
        );

        assertEq(
            loanManagerHarness.loanState(_debtId),
            _loanState,
            "1 :: loan state should remain unchanged."
        );

        assertEq(
            loanManagerHarness.loanLastChecked(_debtId),
            _loanLastChecked,
            "2 :: loan last checked should remain unchanged."
        );

        if (_contractTerms.gracePeriod > 0) {
            vm.warp(_now + _contractTerms.gracePeriod);
            vm.startPrank(address(loanAccountantHarness));
            loanAccountantHarness.implementer_debtUpdater(_debtId);
            vm.stopPrank();

            assertFalse(
                loanAccountantHarness.exposed__updatePermitted(),
                "3 :: update permitted expected to be false."
            );

            assertEq(
                loanManagerHarness.loanState(_debtId),
                _ACTIVE_STATE_,
                "4 :: loan state should be updated."
            );

            assertEq(
                loanManagerHarness.loanLastChecked(_debtId),
                _now + _contractTerms.gracePeriod,
                "5 :: loan last checked should be updated."
            );
        }

        vm.warp(_now + _contractTerms.gracePeriod + _contractTerms.duration);
        vm.startPrank(address(loanAccountantHarness));
        loanAccountantHarness.implementer_debtUpdater(_debtId);
        vm.stopPrank();
    }

    /* ------------ LoanAccountant.updatePermittedLocker() ------------ */
    /**
     * Fuzz test the update permitted locker modifier without a debt balance.
     *
     * @param _debtId The debt id to use for the test.
     *
     * @dev Full pass if the update permitted flag is always true.
     */
    function testLoanAccountant_Fuzz_UpdatePermittedLocker_NoBalance(
        uint256 _debtId
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "0 :: update permitted expected to be false."
        );

        // Note: Everything below this should result in the update permitted
        // flag being true due to no balance.
        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _ACTIVE_GRACE_STATE_
        );
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertTrue(
            loanAccountantHarness.exposed__updatePermitted(),
            "1 :: update permitted expected to be true."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _UNDEFINED_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertTrue(
            loanAccountantHarness.exposed__updatePermitted(),
            "2 :: update permitted expected to be true."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _ACTIVE_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        _validateStateChangesWithoutTimeWarp(_debtId);
    }

    /**
     * Fuzz test the update permitted locker modifier with a debt balance.
     *
     * @param _debtId The debt id to use for the test.
     * @param _contractTerms The contract terms to use for the test.
     *
     * @dev Full pass if the update permitted flag is true only when the
     * debt is not closed nor expired.
     */
    function testLoanAccountant_Fuzz_UpdatePermittedLocker_Balance(
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        vm.assume(_contractTerms.principal > 0);

        // Clean contract terms.
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        try
            loanManagerHarness.exposed__validateLoanTerms(
                _packedContractTerms,
                block.timestamp.toUint64(),
                _contractTerms.principal
            )
        {} catch (bytes memory) {
            vm.assume(false);
        }

        uint256 _activeLoanIndex = 1;

        // Pack and store the contract terms.
        uint64 _now = uint64(block.timestamp);
        loanManagerHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Mint lender tokens.
        anzaTokenHarness.exposed__mint(
            lender,
            _debtId.debtIdToLenderTokenId(),
            _contractTerms.principal
        );

        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);
        _validateStateChangesWithoutTimeWarp(_debtId);

        // Advance time to loan close.
        // Note: Everything below this should result in the update permitted
        // flag being false.
        vm.warp(_now + _contractTerms.gracePeriod + _contractTerms.duration);

        loanManagerHarness.exposed__updateLoanState(_debtId, _DEFAULT_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "2 :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _COLLECTION_STATE_
        );
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "3 :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _AUCTION_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "4 :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _AWARDED_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "5 :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _PAID_PENDING_STATE_
        );
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "6 :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _CLOSE_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "7 :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(_debtId, _PAID_STATE_);
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "8 :: update permitted expected to be false."
        );

        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _CLOSE_DEFAULT_STATE_
        );
        loanAccountantHarness.implementer_updatePermittedLocker(_debtId);

        assertFalse(
            loanAccountantHarness.exposed__updatePermitted(),
            "9 :: update permitted expected to be false."
        );
    }

    /* --------------- LoanAccountant.onlyActiveLoan() ---------------- */
    /**
     * Fuzz test the only active loan modifier.
     *
     * @param _debtId The debt id to use for the test.
     *
     * @dev Full pass if the modifier only reverts when the loan is in an inactive
     * state.
     */
    function testLoanAccountant_Fuzz_OnlyActiveLoan(uint256 _debtId) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        // Loan state _UNDEFINED_STATE_.
        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _ACTIVE_GRACE_.
        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _ACTIVE_GRACE_STATE_
        );
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _ACTIVE_STATE_.
        loanManagerHarness.exposed__updateLoanState(_debtId, _ACTIVE_STATE_);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _DEFAULT_STATE_.
        loanManagerHarness.exposed__updateLoanState(_debtId, _DEFAULT_STATE_);

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _COLLECTION__STATE_.
        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _COLLECTION_STATE_
        );

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _AUCTION_STATE_.
        loanManagerHarness.exposed__updateLoanState(_debtId, _AUCTION_STATE_);

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _AWARDED_STATE_.
        loanManagerHarness.exposed__updateLoanState(_debtId, _AWARDED_STATE_);

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _PAID_PENDING_STATE_.
        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _PAID_PENDING_STATE_
        );

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _CLOSE_STATE_.
        loanManagerHarness.exposed__updateLoanState(_debtId, _CLOSE_STATE_);

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _PAID_STATE_.
        loanManagerHarness.exposed__updateLoanState(_debtId, _PAID_STATE_);

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);

        // Loan state _CLOSE_DEFAULT_STATE_.
        loanManagerHarness.exposed__updateLoanState(
            _debtId,
            _CLOSE_DEFAULT_STATE_
        );

        vm.expectRevert(StdCodecErrors.InactiveLoanState.selector);
        loanAccountantHarness.implementer_onlyActiveLoan(_debtId);
    }
}
