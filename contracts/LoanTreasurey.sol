// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {StdTreasureyErrors} from "@custom-errors/StdTreasureyErrors.sol";
import {StdManagerErrors} from "@custom-errors/StdManagerErrors.sol";

import {ILoanTreasurey} from "@lending-interfaces/ILoanTreasurey.sol";
import {AnzaDebtExchange} from "@base/AnzaDebtExchange.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LoanTreasurey is ILoanTreasurey, AnzaDebtExchange {
    using Address for address payable;

    constructor() AnzaDebtExchange() {}

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(AnzaDebtExchange) returns (bool) {
        return
            _interfaceId == type(ILoanTreasurey).interfaceId ||
            AnzaDebtExchange.supportsInterface(_interfaceId);
    }

    /**
     * Deposits a payment into the debt associated with the debt ID.
     *
     * @notice This function does not check the sender. It is assumed
     * that the payment sponsor is okay with the payment being deposited
     * without this check. This function can be used to reduce gas costs
     * instead of using the `depositPayment` function as long as the sender
     * is sure of the debt ID.
     *
     * @param _sponsor The sponsor address of the debt.
     * @param _debtId The debt ID to deposit the payment.
     *
     * @dev Anyone can call this function.
     * @dev Only active loans can receive payments.
     * @dev This function is non-reentrant.
     *
     * @return A boolean indicating if the payment was deposited.
     */
    function sponsorPayment(
        address _sponsor,
        uint256 _debtId
    )
        external
        payable
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        nonReentrant
        returns (bool)
    {
        uint256 _payment = msg.value;

        // Overpayments checked when burning lender debt tokens.
        // Therefore, no need to check here.
        if (_payment == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

        uint256 _excess = _depositPayment(_sponsor, _debtId, _payment);
        if (_excess > 0) _depositFunds(_sponsor, _excess);

        return true;
    }

    /**
     * Deposits a payment into the debt associated with the debt ID.
     *
     * @notice Overpayments are inherintely not allowed due to the burning
     * of lender debt tokens. This function will revert if the payment is
     * greater than the debt balance.
     *
     * @param _debtId The debt ID to deposit the payment.
     *
     * @dev Payments of 0 are reverted.
     * @dev Only the borrower of the debt can call this function.
     * @dev Only active loans can receive payments.
     * @dev This function is non-reentrant.
     *
     * @return A boolean indicating if the payment was deposited.
     */
    function depositPayment(
        uint256 _debtId
    )
        external
        payable
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        nonReentrant
        returns (bool)
    {
        if (msg.value == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

        address _borrower = msg.sender;

        if (_anzaToken.borrowerOf(_debtId) != _borrower)
            revert StdManagerErrors.InvalidParticipant();

        // Deposit payment to debt.
        uint256 _excess = _depositPayment(_borrower, _debtId, msg.value);

        // Deposit excess funds to PaymentBook record.
        if (_excess > 0) _depositFunds(_borrower, _excess);

        return true;
    }

    /**
     * Withdraw funds from the caller's balance.
     *
     * @param _amount The amount to withdraw.
     *
     * @dev This function is non-reentrant.
     * @dev This function reverts if the amount is zero.
     * @dev This function reverts if the amount is greater than the
     * withdrawable balance.
     *
     * @return A boolean indicating if the withdrawal was successful.
     */
    function withdrawFromBalance(
        uint256 _amount
    ) external nonReentrant returns (bool) {
        if (_amount == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

        address _payee = msg.sender;

        // Withdraw funds from PaymentBook record.
        _withdrawFunds(_payee, _amount);

        // Withdraw funds to payee.
        (bool _success, ) = _payee.call{value: _amount}("");
        if (!_success) revert StdTreasureyErrors.FailedWithdrawal();

        return _success;
    }

    /**
     * Withdraw collateral from the collateral vault.
     *
     * This function initiates a withdrawal of a collateral ERC721 token from
     * the collateral vault. The collateral vault will transfer the token to
     * the caller of this function.
     *
     * @param _debtId The debt ID of the collateral to withdraw.
     *
     * @dev This function is non-reentrant.
     *
     * See {CollateralVault.withdraw}.
     *
     * @return A boolean indicating if the withdrawal was successful.
     */
    function withdrawCollateral(
        uint256 _debtId
    ) external nonReentrant returns (bool) {
        return _collateralVault.withdraw(msg.sender, _debtId);
    }
}
