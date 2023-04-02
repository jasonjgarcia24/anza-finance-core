// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ILoanCollateralVaultEvents} from "./interfaces/ILoanCollateralVaultEvents.t.sol";
import {ILoanTreasureyEvents} from "./interfaces/ILoanTreasureyEvents.t.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {console, stdError, LoanContractSubmitted} from "./LoanContract.t.sol";

contract LoanCollateralTreasureyUnitTest is
    ILoanTreasureyEvents,
    ILoanCollateralVaultEvents,
    LoanContractSubmitted
{
    function setUp() public virtual override {
        super.setUp();
    }

    function payLoan(uint256 _debtId, uint256 _payment) public virtual {
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);
        (bool _success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success);
        vm.stopPrank();
    }

    /*
     * @note LoanTreasurey state variables validation upon initial
     * contract deployment.
     */
    function testTreasureyStateVars() public {
        assertEq(loanTreasurer.loanContract(), address(loanContract));
        assertEq(
            loanTreasurer.loanCollateralVault(),
            address(loanCollateralVault)
        );
        assertEq(loanTreasurer.anzaToken(), address(anzaToken));
        assertEq(loanTreasurer.poolBalance(), 0);
    }

    /*
     * @note LoanTreasurey::sponsorPayment should allow anyone.
     */
    function testFuzzSponsorPayment(address _sender) public {
        vm.assume(_sender != address(0));

        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.deal(_sender, 1 ether);
        vm.startPrank(_sender);
        vm.expectEmit(true, true, true, true);
        emit Deposited(_debtId, _sender, 1 wei);
        (bool success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _sender,
                _debtId
            )
        );
        require(success);
        vm.stopPrank();
    }

    /*
     * @note LoanTreasurey::depositPayment should allow only the
     * borrower.
     */
    function testDepositPayment() public {
        vm.deal(admin, 1 ether);
        vm.deal(address(loanContract), 1 ether);
        vm.deal(address(loanTreasurer), 1 ether);
        vm.deal(address(loanCollateralVault), 1 ether);
        vm.deal(borrower, 1 ether);

        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _loanTreasurerBalance = address(loanTreasurer).balance;
        uint256 _lenderBalance = loanTreasurer.withdrawableBalance(lender);

        // DENY :: Try admin
        vm.startPrank(admin);
        (bool success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success == false);
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(_loanTreasurerBalance, address(loanTreasurer).balance);
        assertEq(_lenderBalance, loanTreasurer.withdrawableBalance(lender));

        // DENY :: Try loan contract
        vm.startPrank(address(loanContract));
        (success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success == false);
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(_loanTreasurerBalance, address(loanTreasurer).balance);
        assertEq(_lenderBalance, loanTreasurer.withdrawableBalance(lender));

        // DENY :: Try loan treasurer
        vm.startPrank(address(loanTreasurer));
        (success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success == false);
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(_loanTreasurerBalance, address(loanTreasurer).balance);
        assertEq(_lenderBalance, loanTreasurer.withdrawableBalance(lender));

        // DENY :: Try loan collateral vault
        vm.startPrank(address(loanCollateralVault));
        (success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success == false);
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(_loanTreasurerBalance, address(loanTreasurer).balance);
        assertEq(_lenderBalance, loanTreasurer.withdrawableBalance(lender));

        // SUCCEED :: Try borrower
        vm.startPrank(borrower);
        vm.expectEmit(true, true, true, true);
        emit Deposited(_debtId, borrower, 1 wei);
        (success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success);
        vm.stopPrank();

        // Balances should change in proportion to deposit
        assertEq(
            address(loanTreasurer).balance,
            _loanTreasurerBalance + uint256(1 wei)
        );
        assertEq(
            _lenderBalance + uint256(1 wei),
            loanTreasurer.withdrawableBalance(lender)
        );
    }

    function testFuzzDepositPaymentDenied(address _sender) public {
        vm.assume(_sender != borrower);

        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.deal(_sender, 1 ether);
        vm.startPrank(_sender);
        vm.expectRevert(
            abi.encodeWithSelector(InvalidParticipant.selector, _sender)
        );
        (bool success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _sender,
                _debtId
            )
        );
        require(success == false);
        vm.stopPrank();
    }

    /*
     * @note LoanTreasurey::withdrawPayment should allow anyone with
     * a nonzero balance to withdraw funds.
     */
    function testWithdrawPayment() public {
        // Setup
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _payment = _PRINCIPAL_;
        payLoan(_debtId, _payment);

        // Withdraw
        uint256 _lenderBalance = loanTreasurer.withdrawableBalance(lender);

        vm.startPrank(lender);
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(lender, _payment);
        loanTreasurer.withdrawFromBalance(_payment);
        vm.stopPrank();

        assert(
            _lenderBalance - _payment ==
                loanTreasurer.withdrawableBalance(lender)
        );
    }

    function testFuzzWithdrawPayment(uint256 _payment) public {
        _payment = bound(_payment, 0, _PRINCIPAL_ * 2);
        bool invalidPayment = _payment == 0 || _payment > _PRINCIPAL_;

        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.deal(borrower, _payment);
        vm.startPrank(borrower);
        (bool success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(success || invalidPayment);
        vm.stopPrank();

        // Withdraw
        uint256 _lenderBalance = loanTreasurer.withdrawableBalance(lender);

        vm.startPrank(lender);
        if (_payment == 0) {
            vm.expectRevert(
                abi.encodeWithSelector(InvalidFundsTransfer.selector)
            );
        } else if (_payment > _PRINCIPAL_) {
            vm.expectRevert(stdError.arithmeticError);
        } else {
            vm.expectEmit(true, true, true, true);
        }
        emit Withdrawn(lender, _payment);
        loanTreasurer.withdrawFromBalance(_payment);
        vm.stopPrank();

        if (!invalidPayment || _payment == 0) {
            assert(
                _lenderBalance - _payment ==
                    loanTreasurer.withdrawableBalance(lender)
            );
        }
    }

    /*
     * @note LoanTreasurey::withdrawCollateral should allow only the
     * borrower to withdraw collateral when the loan is paid in full.
     */
    function testWithdrawCollateral() public {
        // Pay off loan
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _payment = _PRINCIPAL_;
        payLoan(_debtId, _payment);

        assertEq(demoToken.ownerOf(collateralId), address(loanCollateralVault));

        // Withdraw
        vm.startPrank(borrower);
        vm.expectEmit(true, true, true, true);
        emit WithdrawnCollateral(borrower, address(demoToken), collateralId);
        bool success = loanTreasurer.withdrawCollateral(_debtId);
        require(success);
        vm.stopPrank();

        assertEq(demoToken.ownerOf(collateralId), borrower);
    }
}
