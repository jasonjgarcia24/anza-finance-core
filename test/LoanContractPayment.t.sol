// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ILoanContractEvents} from "./interfaces/ILoanContractEvents.t.sol";
import {Test, console, LoanContractSubmitted} from "./LoanContract.t.sol";

contract LoanContractPayoff is LoanContractSubmitted, ILoanContractEvents {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPayoff() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (bool success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _PRINCIPAL_);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        success = loanTreasurer.withdrawPayment(_PRINCIPAL_);
        require(success);
        vm.stopPrank();
    }

    function testPayoffNonBorrower() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.expectRevert(
            abi.encodeWithSelector(InvalidParticipant.selector, alt_account)
        );

        // Pay off loan
        vm.deal(alt_account, _PRINCIPAL_);
        vm.startPrank(alt_account);
        (bool success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        vm.stopPrank();
    }
}
