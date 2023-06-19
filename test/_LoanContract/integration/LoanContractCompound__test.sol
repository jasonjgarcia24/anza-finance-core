// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import "@lending-constants/LoanContractStates.sol";
import "@lending-constants/LoanContractFIRIntervals.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {LoanSigned} from "@test-contract/LoanContract__test.sol";
import {LoanContractSubmitFunctions} from "@test-contract-integration/LoanContractSubmission__test.sol";
import {ILoanContractEvents} from "@test-contract-interfaces/ILoanContractEvents__test.sol";

contract LoanContractCompounding is LoanContractSubmitFunctions {
    function setUp() public virtual override {
        super.setUp();
    }

    function testLoanContractCompound__BasicCompoundingInterest() public {
        /*
         * Setup
         */
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0, "0 :: no debts should exist.");

        ContractTerms memory _contractTerms = ContractTerms({
            firInterval: _360_DAILY_,
            fixedInterestRate: 100,
            isFixed: 0,
            commital: 0,
            principal: 2,
            gracePeriod: _GRACE_PERIOD_,
            duration: uint32(_360_DAILY_MULTIPLIER_ * 2),
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        uint256 _collateralNonce = loanContract.collateralNonce(
            address(demoToken),
            collateralId
        );

        (, bytes memory _expectedData) = initLoanContractExpectations(
            _contractTerms
        );

        (bool _success, bytes memory _data) = createLoanContract(
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        compareInitLoanContractError(_data, _expectedData);

        require(_success, "2 :: loan contract creation failed.");

        _debtId = loanContract.totalDebts();

        /*
         * Testing
         */
        uint256 _initialLoanLastChecked = loanContract.loanLastChecked(_debtId);
        assertGt(
            _initialLoanLastChecked,
            block.timestamp,
            "2 :: loan last checked should be greater than now."
        );

        // loanTreasurer.updateDebt(_debtId);
        // assertEq(
        //     loanContract.loanLastChecked(_debtId),
        //     _initialLoanLastChecked,
        //     "3 :: loan last checked should be unchanged."
        // );

        // // FIR interval default should be _360_DAILY_
        // vm.warp(
        //     loanContract.loanStart(_debtId) +
        //         _GRACE_PERIOD_ +
        //         _360_DAILY_MULTIPLIER_ +
        //         1
        // );

        // vm.expectEmit(true, true, true, true);
        // emit LoanStateChanged(_debtId, _ACTIVE_STATE_, _ACTIVE_GRACE_STATE_);
        // uint256 _now = block.timestamp;
        // loanTreasurer.updateDebt(_debtId);

        // uint256 _loanLastChecked = loanContract.loanLastChecked(_debtId);
        // assertEq(
        //     _loanLastChecked,
        //     _now,
        //     "4 :: loan last checked should be updated to now."
        // );
        // assertGt(
        //     _loanLastChecked,
        //     _initialLoanLastChecked,
        //     "5 :: loan last checked should be greater than before."
        // );

        // assertEq(
        //     loanContract.debtBalance(_debtId),
        //     _contractTerms.principal * 2,
        //     "6 :: debt balance should be doubled."
        // );
    }

    function testLoanContractCompound__FuzzBasicCompoundingInterest(
        uint32 _principal
    ) public {
        // /*
        //  * Setup
        //  */
        // uint32 _gracePeriod = 0;
        // uint32 _timeMultiplier = uint32(_SECONDLY_MULTIPLIER_);
        // uint256 _debtId = loanContract.totalDebts();
        // assertEq(_debtId, 0, "0 :: no debts should exist.");
        // ContractTerms memory _contractTerms = ContractTerms({
        //     firInterval: _SECONDLY_,
        //     fixedInterestRate: 100,
        //     isFixed: 0,
        //     commital: 0,
        //     principal: uint256(_principal),
        //     gracePeriod: _gracePeriod,
        //     duration: uint32(_timeMultiplier * 2),
        //     termsExpiry: _TERMS_EXPIRY_,
        //     lenderRoyalties: _LENDER_ROYALTIES_
        // });
        // uint256 _collateralNonce = loanContract.collateralNonce(
        //     address(demoToken),
        //     collateralId
        // );
        // bool _expectedSuccess = initLoanContractExpectations(_contractTerms);
        // bool _success = createLoanContract(
        //     collateralId,
        //     _collateralNonce,
        //     _contractTerms
        // );
        // if (!_success && !_expectedSuccess) return;
        // require(_success, "1 :: loan contract creation failed.");
        // _debtId = loanContract.totalDebts();
        // /*
        //  * Testing
        //  */
        // uint256 _initialLoanLastChecked = loanContract.loanLastChecked(_debtId);
        // assertGt(
        //     _initialLoanLastChecked,
        //     block.timestamp,
        //     "2 :: loan last checked should be greater than now."
        // );
        // loanTreasurer.updateDebt(_debtId);
        // assertEq(
        //     loanContract.loanLastChecked(_debtId),
        //     _initialLoanLastChecked,
        //     "3 :: loan last checked should be unchanged."
        // );
        // // FIR interval default should be _360_DAILY_
        // vm.warp(
        //     loanContract.loanStart(_debtId) +
        //         _contractTerms.gracePeriod +
        //         _timeMultiplier +
        //         1
        // );
        // uint256 _now = block.timestamp;
        // vm.expectEmit(true, true, true, true);
        // emit LoanStateChanged(_debtId, _ACTIVE_STATE_, _ACTIVE_GRACE_STATE_);
        // loanTreasurer.updateDebt(_debtId);
        // uint256 _loanLastChecked = loanContract.loanLastChecked(_debtId);
        // assertEq(
        //     _loanLastChecked,
        //     _now,
        //     "4 :: loan last checked should be updated to now."
        // );
        // assertGt(
        //     _loanLastChecked,
        //     _initialLoanLastChecked,
        //     "5 :: loan last checked should be greater than before."
        // );
        // assertEq(
        //     loanContract.debtBalance(_debtId),
        //     _contractTerms.principal * 2,
        //     "6 :: debt balance should be doubled."
        // );
    }

    function testLoanContractCompound__BasicLenderCompoundingSubmitProposal()
        public
    {
        /*
         * Setup
         */
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0, "0 :: no debts should exist.");

        ContractTerms memory _contractTerms = ContractTerms({
            firInterval: _360_DAILY_,
            fixedInterestRate: 1,
            isFixed: 0,
            commital: 0,
            principal: 1,
            gracePeriod: _GRACE_PERIOD_,
            duration: uint32(_360_DAILY_MULTIPLIER_ * 2),
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        uint256 _collateralNonce = loanContract.collateralNonce(
            address(demoToken),
            collateralId
        );

        (, bytes memory _expectedData) = initLoanContractExpectations(
            _contractTerms
        );

        (bool _success, bytes memory _data) = createLoanContract(
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        compareInitLoanContractError(_data, _expectedData);

        require(_success, "1 :: loan contract creation failed.");

        _debtId = loanContract.totalDebts();

        /*
         * Testing
         */
    }
}
