// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {StdTreasureyErrors} from "@custom-errors/StdTreasureyErrors.sol";

import {IPaymentBook} from "@lending-databases/interfaces/IPaymentBook.sol";
import {PaymentBookAccessController} from "@lending-access/PaymentBookAccessController.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract PaymentBook is
    IPaymentBook,
    PaymentBookAccessController,
    ReentrancyGuard
{
    mapping(address account => uint256) private __withdrawableBalance;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(PaymentBookAccessController) returns (bool) {
        return
            _interfaceId == type(IPaymentBook).interfaceId ||
            PaymentBookAccessController.supportsInterface(_interfaceId);
    }

    /**
     * Public function to deposit funds into the `_payee` addresses
     * withdrawable balance.
     *
     * @notice This function is payable.
     *
     * @param _payee The account to receive funds in their withdrawable balance.
     *
     * @dev The _depositFunds function is non-reentrant.
     */
    function depositFunds(address _payee) public payable nonReentrant {
        _depositFunds(type(uint256).max, msg.sender, _payee, msg.value);
    }

    /**
     * Public function to deposit funds into the `_payee` addresses
     * withdrawable balance.
     *
     * @notice This function is payable.
     *
     * @param _debtId The debt ID to deposit the payment.
     * @param _payer The payer to deposit funds.
     * @param _payee The account to receive funds in their withdrawable balance.
     *
     * @dev The _depositFunds function is non-reentrant.
     */
    function depositFunds(
        uint256 _debtId,
        address _payer,
        address _payee
    ) public payable nonReentrant {
        _depositFunds(_debtId, _payer, _payee, msg.value);
    }

    /**
     * External function to return the withdrawable balance of the `_account`.
     *
     * @param _account The account to withdraw funds from.
     *
     * @return The withdrawable balance of the `_account`.
     */
    function withdrawableBalance(
        address _account
    ) external view returns (uint256) {
        return __withdrawableBalance[_account];
    }

    /**
     * Internal function to deposit funds into the `_account` addresses
     * withdrawable balance.
     *
     * @notice This function is not payable.
     *
     * @notice Reentrancy is not handled here. If reentrancy is not handled
     * earlier in the call stack, reentrancy attacks are possible.
     *
     * @param _debtId The debt ID to deposit the payment.
     * @param _payer The payer to deposit funds.
     * @param _payee The account to receive funds in their withdrawable balance.
     * @param _amount The amount of funds to deposit.
     *
     * Emits a {Deposited} event.
     */
    function _depositFunds(
        uint256 _debtId,
        address _payer,
        address _payee,
        uint256 _amount
    ) internal {
        __withdrawableBalance[_payee] += _amount;

        emit Deposited(_debtId, _payer, _payee, _amount);
    }

    /**
     * Internal function to withdraw funds from the `_account` addresses
     * withdrawable balance.
     *
     * @notice Reentrancy is not handled here. If reentrancy is not handled
     * earlier in the call stack, reentrancy attacks are possible.
     *
     * @param _account The account to withdraw funds.
     * @param _amount The amount of funds to withdraw.
     *
     * Emits a {Withdrawn} event.
     */
    function _withdrawFunds(address _account, uint256 _amount) internal {
        __withdrawableBalance[_account] -= _amount;

        emit Withdrawn(_account, _amount);
    }

    /**
     * Internal function to sort out the payment of a debt.
     *
     * This function handles the payment of a debt. The debt balance is
     * determined by the amount of ADT the lender has.
     *
     * @notice Refunds are not handled here. If refunds are not handled
     * earlier in the call stack, excess payments will be lost.
     *
     * @notice Reentrancy is not handled here. If reentrancy is not handled
     * earlier in the call stack, reentrancy attacks are possible.
     *
     * Scenario #1:
     *   If the payment is sufficient to pay off the debt, the debt will be
     *   payed off.
     *
     * Scenario #2:
     *   If the payment is less than the debt balance, the debt will be
     *   partially paid off.
     *
     * @param _payer The payer of the debt.
     * @param _debtId The debt ID to deposit the payment.
     * @param _payment The amount of payment to deposit.
     *
     * @dev This function reverts if the debt ID is invalid.
     * @dev This function returns the payment if the balance or payment is
     * 0.
     *
     * Emits a {Deposited} event.
     *
     * @return The excess amount of payment that was not deposited.
     */
    function _depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) internal virtual returns (uint256) {
        address _lender = _anzaToken.lenderOf(_debtId);
        uint256 _balance = _anzaToken.totalSupply(
            _anzaToken.lenderTokenId(_debtId)
        );

        // If either the balance or payment is 0, return the payment
        // as the excess.
        if (_balance == 0 || _payment == 0) return _payment;

        // Update lender's withdrawable balance, burn lender tokens,
        // and emit a Deposited event.
        if (_balance > _payment) {
            __withdrawableBalance[_lender] += _payment;

            _anzaToken.burnLenderToken(_debtId, _payment);

            emit Deposited(_debtId, _payer, _lender, _payment);

            return 0;
        } else {
            console.log("burning lender token");
            __withdrawableBalance[_lender] += _balance;

            _anzaToken.burnLenderToken(_debtId, _balance);

            emit Deposited(_debtId, _payer, _lender, _balance);

            return _payment - _balance;
        }
    }
}
