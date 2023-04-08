// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ILoanContractEvents} from "../interfaces/ILoanContractEvents.t.sol";
import {Test, console, LoanSigned} from "../LoanContract.t.sol";
import {LoanContractSubmitFunctions} from "./LoanContractSubmission.t.sol";
import {LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "../../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractStates as States} from "../../contracts/libraries/LibLoanContractConstants.sol";

contract LoanContractCompounding is LoanContractSubmitFunctions, LoanSigned {
    function setUp() public virtual override {
        super.setUp();
    }

    function testBasicCompoundingInterest() public {
        /*
         * Setup
         */
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _FIR_INTERVAL_)
            mstore(0x1f, _FIXED_INTEREST_RATE_)
            mstore(0x1d, _PRINCIPAL_)
            mstore(0x0d, _GRACE_PERIOD_)
            mstore(0x09, _DURATION_)
            mstore(0x05, _TERMS_EXPIRY_)
            mstore(0x01, _LENDER_ROYALTIES_)

            _contractTerms := mload(0x20)
        }

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        bytes memory _signature = abi.encodePacked(r, s, v);

        uint256 _debtId = loanContract.totalDebts();

        // Submit proposal
        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            10,
            62208000,
            _GRACE_PERIOD_,
            _TERMS_EXPIRY_
        );

        vm.deal(lender, uint256(10) + 1 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: 10}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                collateralId,
                _signature
            )
        );
        require(success);
        vm.stopPrank();

        /*
         * Testing
         */
        uint256 _initialLoanLastChecked = loanContract.loanLastChecked(_debtId);
        assertGt(_initialLoanLastChecked, block.timestamp);

        loanTreasurer.updateDebt(_debtId);
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _initialLoanLastChecked
        );

        // FIR interval default should be _360_DAILY_
        vm.warp(loanContract.loanStart(_debtId) + 60 * 60 * 24 * 360);

        vm.expectEmit(true, true, true, true);
        emit LoanStateChanged(
            _debtId,
            States._ACTIVE_STATE_,
            States._ACTIVE_GRACE_STATE_
        );

        // assertEq(loanTreasurer.updateDebt(_debtId), 11);
        assertGt(
            loanContract.loanLastChecked(_debtId),
            _initialLoanLastChecked
        );
    }

    function testBasicLenderCompoundingSubmitProposal() public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _PRINCIPAL_,
            _DURATION_,
            _GRACE_PERIOD_,
            _TERMS_EXPIRY_
        );

        // Submit proposal
        vm.deal(lender, _PRINCIPAL_);
        vm.startPrank(lender);
        (bool success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                contractTerms,
                address(demoToken),
                collateralId,
                signature
            )
        );
        require(success);
        vm.stopPrank();

        if (_PRINCIPAL_ == 0 || _DURATION_ == 0 || _TERMS_EXPIRY_ == 0) {
            return;
        }

        // Verify balance of borrower token is zero
        uint256 _borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        assertEq(anzaToken.balanceOf(borrower, _borrowerTokenId), 0);

        // Mint replica token
        vm.deal(borrower, 1 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: States._ACTIVE_GRACE_STATE_,
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: 0,
                gracePeriod: 0,
                duration: _DURATION_,
                termsExpiry: 0
            })
        );

        // Verify loan participants
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_);

        // Verify token balances
        verifyTokenBalances(
            borrower,
            lender,
            address(anzaToken),
            _debtId,
            _PRINCIPAL_
        );

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }
}
