// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ILoanNotaryErrors} from "../../contracts/interfaces/ILoanNotary.sol";
import {ILoanContractEvents} from "../interfaces/ILoanContractEvents.t.sol";
import {ILoanTreasureyEvents} from "../interfaces/ILoanTreasureyEvents.t.sol";
import {Test, console, stdError, LoanContractSubmitted} from "../LoanContract.t.sol";

contract LoanContractPayoff is LoanContractSubmitted {
    function setUp() public virtual override {
        super.setUp();
    }

    function testLoanContractPayment__Payoff() public {
        uint256 _debtId = loanContract.totalDebts();

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _PRINCIPAL_);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        _success = loanTreasurer.withdrawFromBalance(_PRINCIPAL_);
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }

    function testLoanContractPayment__PayoffNonBorrower() public {
        uint256 _debtId = loanContract.totalDebts();

        vm.expectRevert(
            abi.encodeWithSelector(
                ILoanNotaryErrors.InvalidParticipant.selector,
                alt_account
            )
        );

        // Pay off loan expected failure
        vm.deal(alt_account, _PRINCIPAL_);
        vm.startPrank(alt_account);
        (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );

        // Pay off loan expected _success
        (_success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                alt_account,
                _debtId
            )
        );
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _PRINCIPAL_);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        _success = loanTreasurer.withdrawFromBalance(_PRINCIPAL_);
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }
}

contract LoanContractPayment is LoanContractSubmitted {
    function setUp() public virtual override {
        super.setUp();
    }

    function testLoanContractPayment__Payment() public {
        uint256 _debtId = loanContract.totalDebts();
        uint256 _payment = _PRINCIPAL_ / 10;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);
        (bool _success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _payment);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        _success = loanTreasurer.withdrawFromBalance(_payment);
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(loanTreasurer.withdrawableBalance(lender), 0);
    }

    function testLoanContractPayment__Overpayment() public {
        uint256 _debtId = loanContract.totalDebts();
        uint256 _payment = _PRINCIPAL_ + 1 ether;

        // Initial borrower balance and withdrawal
        // Used to set all balances to zero.
        vm.startPrank(borrower);
        assertEq(
            loanTreasurer.withdrawableBalance(borrower),
            _PRINCIPAL_,
            "0 :: borrower's initial withdrawable balance should be the principal."
        );

        bool _success = loanTreasurer.withdrawFromBalance(_PRINCIPAL_);
        require(_success == true, "1 :: withdraw payment should succeed.");

        assertEq(
            loanTreasurer.withdrawableBalance(borrower),
            0,
            "2 :: borrower's withdrawable balance should be 0."
        );

        // Pay off loan
        vm.deal(borrower, _payment);
        (_success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success == true, "3 :: deposit payment should succeed.");
        vm.stopPrank();

        // Ensure lender's withdrawable balance is the princial
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _PRINCIPAL_,
            "4 :: lender's withdrawable balance should be the principal."
        );
        // Ensure borrower's withdrawable balance is 1 ether (the extra)
        assertEq(
            loanTreasurer.withdrawableBalance(borrower),
            1 ether,
            "5 :: borrower's withdrawable balance should be 10^18."
        );

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        // vm.expectRevert(stdError.arithmeticError);
        _success = loanTreasurer.withdrawFromBalance(_PRINCIPAL_);
        require(_success == true, "6 :: withdraw payment should succeed.");
        vm.stopPrank();

        // Allow borrower to withdraw payment
        vm.startPrank(borrower);
        // vm.expectRevert(stdError.arithmeticError);
        _success = loanTreasurer.withdrawFromBalance(1 ether);
        require(_success == true, "7 :: withdraw payment should succeed.");
        vm.stopPrank();

        // Ensure lender's withdrawable balance is 0
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            0,
            "8 :: lender's withdrawable balance should be 0."
        );

        // Ensure borrower's withdrawable balance is 0
        assertEq(
            loanTreasurer.withdrawableBalance(borrower),
            0,
            "9 :: borrower's withdrawable balance should be 0."
        );
    }
}

contract LoanContractWithdrawal is LoanContractSubmitted {
    function setUp() public virtual override {
        super.setUp();
    }

    function testLoanContractPayment__Withdrawal() public {
        uint256 _debtId = loanContract.totalDebts();
        uint256 _withdrawal = _PRINCIPAL_ / 10;

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _PRINCIPAL_);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        _success = loanTreasurer.withdrawFromBalance(_withdrawal);
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _PRINCIPAL_ - _withdrawal
        );
    }

    function testLoanContractPayment__Overwithdrawal() public {
        uint256 _debtId = loanContract.totalDebts();
        uint256 _withdrawal = _PRINCIPAL_ + 1 ether;

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _PRINCIPAL_);

        // Deny lender to over withdraw
        vm.startPrank(lender);
        vm.expectRevert(stdError.arithmeticError);
        _success = loanTreasurer.withdrawFromBalance(_withdrawal);
        require(_success == false);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is unchanged
        assertEq(loanTreasurer.withdrawableBalance(lender), _PRINCIPAL_);
    }
}

contract LoanContractFuzzPayments is LoanContractSubmitted {
    uint256 public updatedCollateralId;

    function setUp() public virtual override {
        super.setUp();
    }

    function testLoanContractPayment__FuzzPayment(uint256 _payment) public {
        // Setup
        _payment = bound(_payment, 0, 2 ** 128);
        mintDemoTokens(1);

        updatedCollateralId = demoToken.totalSupply();
        uint256 _actualPayment = _payment > _PRINCIPAL_
            ? _PRINCIPAL_
            : _payment;

        bool _success = createLoanContract(updatedCollateralId);
        require(_success, "0 :: loan creation failed.");

        uint256 _debtId = loanContract.totalDebts();

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);

        // If _invalidPayment, "AnzaToken: burn amount exceeds totalSupply"
        (_success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success || _payment == 0, "1 :: payment failed.");
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _actualPayment,
            "2 :: lender's withdrawable balance not equal to payment."
        );

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        if (_payment == 0) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanTreasureyEvents.InvalidFundsTransfer.selector
                )
            );
        }
        _success = loanTreasurer.withdrawFromBalance(_actualPayment);
        require(_success || _payment == 0, "3 :: withdrawal failed.");
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            0,
            "4 :: lender's withdrawable balance should be 0."
        );
    }

    function testLoanContractPayment__FuzzWithdrawals(
        uint256 _withdrawal
    ) public {
        bound(_withdrawal, 0, 2 ** 128);

        uint256 _debtId = loanContract.totalDebts();
        uint256 _payment = _PRINCIPAL_;
        bool _invalidWithdrawal = _withdrawal == 0 || _withdrawal > _payment;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);

        (bool _success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success);
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(loanTreasurer.withdrawableBalance(lender), _payment);

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        if (_withdrawal == 0) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanTreasureyEvents.InvalidFundsTransfer.selector
                )
            );
        } else if (_withdrawal > _payment) {
            vm.expectRevert(stdError.arithmeticError);
        }
        _success = loanTreasurer.withdrawFromBalance(_withdrawal);
        require(_success || _invalidWithdrawal);
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        if (_withdrawal <= _payment) {
            assertEq(
                loanTreasurer.withdrawableBalance(lender),
                _invalidWithdrawal ? _payment : _payment - _withdrawal
            );
        }
    }

    function testLoanContractPayment__FuzzExchanges(
        uint256 _payment,
        uint256 _withdrawal
    ) public {
        _payment = bound(_payment, 0, 2 ** 128);
        _withdrawal = bound(_withdrawal, 0, 2 ** 128);

        uint256 _debtId = loanContract.totalDebts();
        uint256 _actualPayment = _payment > _PRINCIPAL_
            ? _PRINCIPAL_
            : _payment;
        bool _invalidWithdrawal = _withdrawal == 0 ||
            _withdrawal > _actualPayment;

        // Pay off loan
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);

        // If _invalidPayment, "AnzaToken: burn amount exceeds totalSupply"
        (bool _success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success || _actualPayment == 0, "0 :: valid payment failed.");
        vm.stopPrank();

        // Ensure lender's withdrawable balance is equal to payment
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _actualPayment,
            "1 :: lender's withdrawable balance is not equal to payment."
        );

        // Allow lender to withdraw payment
        vm.startPrank(lender);
        if (_withdrawal == 0) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanTreasureyEvents.InvalidFundsTransfer.selector
                )
            );
        } else if (_withdrawal > _actualPayment) {
            vm.expectRevert(stdError.arithmeticError);
        }
        _success = loanTreasurer.withdrawFromBalance(_withdrawal);
        require(
            _success || _invalidWithdrawal,
            "2 :: valid withdrawal failed."
        );
        vm.stopPrank();

        // Ensure lender's withdrawable balance reflects withdrawal
        assertEq(
            loanTreasurer.withdrawableBalance(lender),
            _actualPayment == 0 ? 0 : _invalidWithdrawal
                ? _actualPayment
                : _actualPayment - _withdrawal,
            "3 :: lender's withdrawable balance does not reflect withdrawal."
        );
    }
}
