// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {StdTreasureyErrors} from "@custom-errors/StdTreasureyErrors.sol";
import {StdManagerErrors, _INVALID_PARTICIPANT_SELECTOR_} from "@custom-errors/StdManagerErrors.sol";

import {ILoanCollateralVaultEvents} from "./interfaces/ILoanCollateralVaultEvents.t.sol";
import {ILoanTreasureyEvents} from "./interfaces/ILoanTreasureyEvents.t.sol";

import {LoanContractSubmitted} from "./LoanContract.t.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LoanTreasureyUnitTest is
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
    function testLoanTreasurey__StateVars() public {
        assertEq(loanTreasurer.loanContract(), address(loanContract));
        assertEq(loanTreasurer.collateralVault(), address(collateralVault));
        assertEq(loanTreasurer.anzaToken(), address(anzaToken));
    }

    /*
     * @note LoanTreasurey::sponsorPayment should allow anyone.
     */
    function testLoanTreasurey__FuzzSponsorPayment(address _sender) public {
        vm.assume(_sender != address(0));

        uint256 _debtId = loanContract.totalDebts();

        vm.deal(_sender, 1 ether);
        vm.startPrank(_sender);
        (bool _success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _sender,
                _debtId
            )
        );
        assertTrue(_success, "0 :: payment sponsorship failed.");
        vm.stopPrank();
    }

    /*
     * @note LoanTreasurey::depositPayment should allow only the
     * borrower.
     */
    function testLoanTreasurey__DepositPayment() public {
        vm.deal(admin, 1 ether);
        vm.deal(address(loanContract), 1 ether);
        vm.deal(address(loanTreasurer), 1 ether);
        vm.deal(address(collateralVault), 1 ether);
        vm.deal(borrower, 1 ether);

        uint256 _debtId = loanContract.totalDebts();
        uint256 _loanTreasurerBalance = address(loanTreasurer).balance;
        uint256 _lenderBalance = loanTreasurer.withdrawableBalance(lender);

        // DENY :: Try admin
        vm.startPrank(admin);
        (bool _success, bytes memory _data) = address(loanTreasurer).call{
            value: 1 wei
        }(abi.encodeWithSignature("depositPayment(uint256)", _debtId));
        assertTrue(_success == false, "0 :: deposited payment.");
        assertEq(
            bytes4(_data),
            _INVALID_PARTICIPANT_SELECTOR_,
            "1 :: invalid participant error expected."
        );
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(
            _loanTreasurerBalance,
            address(loanTreasurer).balance,
            "2 :: loan treasurer balance should be unchanged."
        );
        assertEq(
            _lenderBalance,
            loanTreasurer.withdrawableBalance(lender),
            "3 :: lender withdrawable balance should be unchanged."
        );

        // DENY :: Try loan contract
        vm.startPrank(address(loanContract));
        (_success, _data) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        assertTrue(_success == false, "4 :: deposited payment.");
        assertEq(
            bytes4(_data),
            _INVALID_PARTICIPANT_SELECTOR_,
            "5 :: invalid participant error expected."
        );
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(
            _loanTreasurerBalance,
            address(loanTreasurer).balance,
            "6 :: loan treasurer balance should be unchanged."
        );
        assertEq(
            _lenderBalance,
            loanTreasurer.withdrawableBalance(lender),
            "7 :: lender withdrawable balance should be unchanged."
        );

        // DENY :: Try loan treasurer
        vm.startPrank(address(loanTreasurer));
        (_success, _data) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        assertTrue(_success == false, "8 :: deposited payment.");
        assertEq(
            bytes4(_data),
            _INVALID_PARTICIPANT_SELECTOR_,
            "9 :: invalid participant error expected."
        );
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(
            _loanTreasurerBalance,
            address(loanTreasurer).balance,
            "10 :: loan treasurer balance should be unchanged."
        );
        assertEq(
            _lenderBalance,
            loanTreasurer.withdrawableBalance(lender),
            "11 :: lender withdrawable balance should be unchanged."
        );

        // DENY :: Try loan collateral vault
        vm.startPrank(address(collateralVault));
        (_success, _data) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        assertTrue(_success == false, "12 :: deposited payment.");
        assertEq(
            bytes4(_data),
            _INVALID_PARTICIPANT_SELECTOR_,
            "13 :: invalid participant error expected."
        );
        vm.stopPrank();

        // Balances should remain unchanged
        assertEq(
            _loanTreasurerBalance,
            address(loanTreasurer).balance,
            "14 :: loan treasurer balance should be unchanged."
        );
        assertEq(
            _lenderBalance,
            loanTreasurer.withdrawableBalance(lender),
            "15 :: lender withdrawable balance should be unchanged."
        );

        // SUCCEED :: Try borrower
        vm.startPrank(borrower);
        // vm.expectEmit(true, true, true, true, address(loanTreasurer));
        // emit Deposited(_debtId, borrower, 1 wei);
        (_success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        assertTrue(_success, "16 :: failed to deposit payment.");
        vm.stopPrank();

        // Balances should change in proportion to deposit
        assertEq(
            address(loanTreasurer).balance,
            _loanTreasurerBalance + uint256(1 wei),
            "17 :: loan treasurer balance should be changed."
        );
        assertEq(
            _lenderBalance + uint256(1 wei),
            loanTreasurer.withdrawableBalance(lender),
            "18 :: lender withdrawable balance should be changed."
        );
    }

    function testLoanTreasurey__FuzzDepositPaymentDenied(
        address _sender
    ) public {
        vm.assume(_sender != borrower);

        uint256 _debtId = loanContract.totalDebts();

        vm.deal(_sender, 1 ether);
        vm.startPrank(_sender);
        // // Revert is expected, but will not pick up
        // vm.expectRevert(
        //     abi.encodeWithSelector(InvalidParticipant.selector, _sender)
        // );
        (bool _success, ) = address(loanTreasurer).call{value: 1 wei}(
            abi.encodeWithSignature(
                "depositPayment(address,uint256)",
                _sender,
                _debtId
            )
        );
        require(_success == false, "0 :: deposited payment.");
        vm.stopPrank();
    }

    /*
     * @note LoanTreasurey::withdrawPayment should allow anyone with
     * a nonzero balance to withdraw funds.
     */
    function testLoanTreasurey__WithdrawPayment() public {
        // Setup
        uint256 _debtId = loanContract.totalDebts();
        payLoan(_debtId, _PRINCIPAL_);

        // Withdraw
        uint256 _lenderBalance = loanTreasurer.withdrawableBalance(lender);

        vm.startPrank(lender);
        vm.expectEmit(true, true, true, true, address(loanTreasurer));
        emit Withdrawn(lender, _PRINCIPAL_);
        loanTreasurer.withdrawFromBalance(_PRINCIPAL_);
        vm.stopPrank();

        assertTrue(
            _lenderBalance - _PRINCIPAL_ ==
                loanTreasurer.withdrawableBalance(lender),
            "0 :: lender balance should be reduced by withdrawal"
        );
    }

    function testLoanTreasurey__FuzzWithdrawPayment(uint256 _payment) public {
        _payment = bound(_payment, 0, _PRINCIPAL_ * 2);
        bool invalidPayment = _payment == 0 || _payment > _PRINCIPAL_;

        uint256 _debtId = loanContract.totalDebts();

        vm.deal(borrower, _payment);
        vm.startPrank(borrower);
        (bool _success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(
            _success || invalidPayment,
            "0 :: deposit should fail if the payment is valid."
        );
        vm.stopPrank();

        // Withdraw
        uint256 _lenderBalance = loanTreasurer.withdrawableBalance(lender);

        vm.startPrank(lender);
        if (_payment == 0) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    StdTreasureyErrors.InvalidFundsTransfer.selector
                )
            );
        } else if (_payment > _PRINCIPAL_) {
            vm.expectRevert(stdError.arithmeticError);
        } else {
            vm.expectEmit(true, true, true, true, address(loanTreasurer));
        }
        emit Withdrawn(lender, _payment);
        loanTreasurer.withdrawFromBalance(_payment);
        vm.stopPrank();

        if (!invalidPayment || _payment == 0) {
            assertTrue(
                _lenderBalance - _payment ==
                    loanTreasurer.withdrawableBalance(lender),
                "1 :: lender balance should be reduced by withdrawal."
            );
        }
    }

    /*
     * @note LoanTreasurey::withdrawCollateral should allow only the
     * borrower to withdraw collateral when the loan is paid in full.
     */
    function testLoanTreasurey__WithdrawCollateral() public {
        // Pay off loan
        uint256 _debtId = loanContract.totalDebts();
        uint256 _payment = _PRINCIPAL_;
        payLoan(_debtId, _payment);

        assertEq(
            demoToken.ownerOf(collateralId),
            address(collateralVault),
            "0 :: collateral vault should be owner of collateral."
        );

        // Withdraw
        vm.startPrank(borrower);
        vm.expectEmit(true, true, true, true, address(collateralVault));
        emit WithdrawnCollateral(borrower, address(demoToken), collateralId);
        bool _success = loanTreasurer.withdrawCollateral(_debtId);
        assertTrue(_success, "1 :: collateral withdrawal should succeed.");
        vm.stopPrank();

        assertEq(demoToken.ownerOf(collateralId), borrower);
    }
}
