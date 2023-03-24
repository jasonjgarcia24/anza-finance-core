// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ILoanContractEvents} from "../interfaces/ILoanContractEvents.t.sol";
import {Test, console, LoanContractSubmitted} from "../LoanContract.t.sol";

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

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }

    function testPayoffNonBorrower() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.expectRevert(
            abi.encodeWithSelector(InvalidParticipant.selector, alt_account)
        );

        // Pay off loan expected failure
        vm.deal(alt_account, _PRINCIPAL_);
        vm.startPrank(alt_account);
        (bool success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );

        // Pay off loan expected success
        (success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("sponsorPayment(uint256)", _debtId)
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

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }
}

contract LoanContractPayment is LoanContractSubmitted, ILoanContractEvents {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPayment() public {
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _payment = _PRINCIPAL_ / 10;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);
        (bool success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _payment);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        success = loanTreasurer.withdrawPayment(_payment);
        require(success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }

    function testOverpayment() public {
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _payment = _PRINCIPAL_ + 1 ether;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);

        // Should revert with "AnzaToken: burn amount exceeds totalSupply"
        (bool success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success == false);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is 0
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);

        // Deny lender to withdraw payment
        vm.startPrank(lender);
        vm.expectRevert(
            abi.encodeWithSelector(InvalidFundsTransfer.selector, _payment)
        );
        success = loanTreasurer.withdrawPayment(_payment);
        require(success == false);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is unchanged
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }
}

contract LoanContractWithdrawal is LoanContractSubmitted, ILoanContractEvents {
    function setUp() public virtual override {
        super.setUp();
    }

    function testWithdrawal() public {
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _withdrawal = _PRINCIPAL_ / 10;

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
        success = loanTreasurer.withdrawPayment(_withdrawal);
        require(success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _PRINCIPAL_ - _withdrawal
        );
    }

    function testOverwithdrawal() public {
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _withdrawal = _PRINCIPAL_ + 1 ether;

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

        // Deny lender to over withdraw
        vm.startPrank(lender);
        vm.expectRevert(
            abi.encodeWithSelector(InvalidFundsTransfer.selector, _withdrawal)
        );
        success = loanTreasurer.withdrawPayment(_withdrawal);
        require(success == false);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is unchanged
        assertEq(loanTreasurer.withdrawableBalance(lender), _PRINCIPAL_);
    }
}

contract LoanContractFuzzPayments is
    LoanContractSubmitted,
    ILoanContractEvents
{
    function setUp() public virtual override {
        super.setUp();
    }

    function testFuzzPayment(uint256 _payment) public {
        bound(_payment, 0, 2 ** 128);

        uint256 _debtId = loanContract.totalDebts() - 1;
        bool _invalidPayment = _payment == 0 || _payment > _PRINCIPAL_;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);

        // If _invalidPayment, "AnzaToken: burn amount exceeds totalSupply"
        (bool success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success || _invalidPayment);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _invalidPayment ? 0 : _payment
        );

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        if (_invalidPayment) {
            vm.expectRevert(
                abi.encodeWithSelector(InvalidFundsTransfer.selector, _payment)
            );
        }
        success = loanTreasurer.withdrawPayment(_payment);
        require(success || _invalidPayment);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }

    function testFuzzWithdrawals(uint256 _withdrawal) public {
        bound(_withdrawal, 0, 2 ** 128);

        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _payment = _PRINCIPAL_ / 10;
        bool _invalidWithdrawal = _withdrawal == 0 || _withdrawal > _payment;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);

        (bool success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _payment);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        if (_invalidWithdrawal) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidFundsTransfer.selector,
                    _withdrawal
                )
            );
        }

        success = loanTreasurer.withdrawPayment(_withdrawal);
        require(success || _invalidWithdrawal);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _invalidWithdrawal ? _payment : _payment - _withdrawal
        );
    }

    function testFuzzExchanges(uint256 _payment, uint256 _withdrawal) public {
        bound(_payment, 0, 2 ** 128);
        bound(_withdrawal, 0, 2 ** 128);

        uint256 _debtId = loanContract.totalDebts() - 1;
        bool _invalidPayment = _payment == 0 || _payment > _PRINCIPAL_;
        bool _invalidWithdrawal = _withdrawal == 0 || _withdrawal > _payment;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);

        // If _invalidPayment, "AnzaToken: burn amount exceeds totalSupply"
        (bool success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success || _invalidPayment);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _invalidPayment ? 0 : _payment
        );

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        if (_invalidPayment || _invalidWithdrawal) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidFundsTransfer.selector,
                    _withdrawal
                )
            );
        }

        success = loanTreasurer.withdrawPayment(_withdrawal);
        require(success || _invalidPayment || _invalidWithdrawal);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _invalidPayment ? 0 : _invalidWithdrawal
                ? _payment
                : _payment - _withdrawal
        );
    }
}
