// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test, console, LoanContractSubmitted} from "./LoanContract.t.sol";

contract LoanContractPayer is LoanContractSubmitted {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPayoff() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        (bool success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success);
        vm.stopPrank();

        assertEq(loanContract.withdrawableBalance(lender), _PRINCIPAL_);

        vm.startPrank(lender);
        success = loanContract.withdrawPayment(_PRINCIPAL_);
        require(success);
        vm.stopPrank();
    }
}
