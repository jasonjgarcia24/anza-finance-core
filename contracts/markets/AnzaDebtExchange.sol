// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_} from "@lending-constants/LoanContractRoles.sol";
import {_DEBT_MARKET_} from "@markets-constants/AnzaDebtMarketRoles.sol";
import {_DEBT_TRANSFER_} from "@tokens-constants/AnzaTokenTransferTypes.sol";
import {StdTreasureyErrors} from "@custom-errors/StdTreasureyErrors.sol";

import {IAnzaDebtExchange} from "@markets-interfaces//IAnzaDebtExchange.sol";
import {LoanAccountant} from "@services/LoanAccountant.sol";

abstract contract AnzaDebtExchange is IAnzaDebtExchange, LoanAccountant {
    constructor() LoanAccountant() {}

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(LoanAccountant) returns (bool) {
        return
            _interfaceId == type(IAnzaDebtExchange).interfaceId ||
            LoanAccountant.supportsInterface(_interfaceId);
    }

    /**
     * Call to seet the Anza Token contract.._
     *
     * @param _anzaTokenAddress The address of the Anza Token contract.
     *
     * See {PaymentBookAccessController._setAnzaToken} for more details.
     *
     * @dev This function can only be called by the admin.
     * @dev This function overrides PaymentBookAccessController.setAnzaToken.
     */
    function setAnzaToken(
        address _anzaTokenAddress
    ) public override onlyRole(_ADMIN_) {
        super._setAnzaToken(_anzaTokenAddress);
    }

    /**
     * A purchase transaction of debt responsibilities from the current borrower
     * to the purchaser.
     *
     * @param _collateralAddress The address of the collateral.
     * @param _collateralId The ID of the collateral.
     * @param _borrower The address of the current borrower selling the debt.
     * @param _purchaser The address of the debt purchaser.
     *
     * @dev Only the debt marketplace can execute this method.
     * @dev This function is non-reentrant.
     * @dev The payment cannot be zero.
     *
     * @return _results true if the debt purchase was successful.
     */
    function executeDebtPurchase(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _purchaser
    )
        external
        payable
        onlyRole(_DEBT_MARKET_)
        nonReentrant
        returns (bool _results)
    {
        if (msg.value == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

        return
            _executeDebtExchange(
                _collateralAddress,
                _collateralId,
                _borrower,
                _purchaser,
                msg.value
            );
    }

    /**
     * A transfer of debt responsibilities from the current borrower to the
     * beneficiary.
     *
     * @param _collateralAddress The address of the collateral.
     * @param _collateralId The ID of the collateral.
     * @param _borrower The address of the current borrower selling the debt.
     * @param _beneficiary The address of the debt beneficiary.
     *
     * @dev Only the debt marketplace can execute this method.
     * @dev This function is non-reentrant.
     *
     * @return _results true if the debt purchase was successful.
     */
    function executeDebtTransfer(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _beneficiary
    ) external onlyRole(_DEBT_MARKET_) nonReentrant returns (bool _results) {
        return
            _executeDebtExchange(
                _collateralAddress,
                _collateralId,
                _borrower,
                _beneficiary,
                0
            );
    }

    /**
     * An exchange of debt responsibilities from the current borrower to the
     * beneficiary.
     *
     * No change is made to the original loan contract nor is an updated debt ID
     * necessary here. In this case, the borrower will forfeit the collateral to
     * the beneficiary at the purchased value, whether zero or nonzero.
     *
     * @notice The _depositPayment() function reverts if the loan is expired,
     * which is in place of the onlyActiveLoan modifier.
     *
     * @notice The __depositPayment() function is a debtUpdater.
     *
     * Scenario #1:
     *   Should the payment cover the cost of all the debts, the payments less
     *   the excess funds is used to close out the loans, the excess funds from
     *   the payment, if any, will be transferred to the original borrower's
     *   account and the beneficiary will be able to withdraw the collateral to
     *   their account.
     *
     * Scenario #2:
     *   Should the payment not cover the entirety of the debt, the
     *   payment is applied directly to the loan, the borrower's withdrawable
     *   balance remains unchanged, and the beneficiary will become the
     *   loan's borrower. In this case, the borrower will forfeit the collateral
     *   to the beneficiary at a lesser cost than the debt's value.
     *
     * @param _collateralAddress The address of the collateral.
     * @param _collateralId The ID of the collateral.
     * @param _borrower The address of the current borrower selling the debt.
     * @param _beneficiary The address of the debt beneficiary.
     * @param _payment The amount of payment to be applied to the debt.
     *
     * @dev Only the debt marketplace can execute this method.
     * @dev Only debts without expired loans can be purchased.
     * @dev The payment can be zero.
     *
     * @return _results True if the debt purchase was successful.
     */
    function _executeDebtExchange(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _beneficiary,
        uint256 _payment
    ) internal returns (bool _results) {
        uint256 _collateralDebtCount = _loanContract.collateralDebtCount(
            _collateralAddress,
            _collateralId
        );

        // Arrays to store token IDs and amounts for debt token transfers.
        uint256[] memory _ids = new uint256[](_collateralDebtCount);
        uint256[] memory _amounts = new uint256[](_collateralDebtCount);

        uint256 _debtId;
        for (uint256 i; i < _collateralDebtCount; ) {
            // Get debt ID for collateral at index.
            (_debtId, ) = _loanContract.collateralDebtAt(
                _collateralAddress,
                _collateralId,
                i
            );

            // Conduct debt purchase and/or transfer.
            _payment = __depositPayment(_beneficiary, _debtId, _payment);

            // Add debt tokens to transfer list.
            _ids[i] = _anzaToken.borrowerTokenId(_debtId);
            _amounts[i] = 1;

            unchecked {
                ++i;
            }
        }

        // If there is payment balance remaining, deposit it to the
        // borrower's withdrawable balance.
        if (_payment > 0)
            _depositFunds(
                type(uint256).max,
                address(this),
                _borrower,
                _payment
            );

        // Transfer debt tokens to beneficiary.
        _anzaToken.safeBatchTransferFrom(
            _borrower,
            _beneficiary,
            _ids,
            _amounts,
            abi.encodePacked(_DEBT_TRANSFER_)
        );

        _results = true;
    }

    /**
     * A refinancing of the loan terms of the current borrower's loan contract.
     *
     * This function will create a new loan contract with the new terms from an
     * existing loan contract. The new loan contract will be assigned to the
     * original borrower and the sponsor of the refinancing, which can be the
     * same or a different lender.
     *
     * @notice This function does not apply a reentrancy guard since it does not
     * directly call a deposit. There is however a reentrancy guard further in
     * the call stack at LoanTreasury.sponsorPayment.
     *
     * Scenario #1:
     *   Should the amount of the refinanced loan be less than the original
     *   loan, the original loan will be reduced by the amount refinanced. The
     *   original loan will remain open and a new loan will be created for the
     *   refinanced amount.
     *
     * Scenario #2:
     *   Should the amount of the refinanced loan be greater than or equal to
     *   the original loan, the original loan will be closed and a new loan
     *   will be created for the refinanced amount.
     *
     * @param _debtId The ID of the debt to be refinanced.
     * @param _borrower The address of the current borrower.
     * @param _purchaser The address of the lender sponsoring the refinancing.
     * @param _contracTerms The contract terms of the new loan.
     *
     * @dev Only the debt marketplace can execute this method.
     * @dev Only active debts can be refinanced.
     * @dev This function updates the debt prior to execution.
     *
     * See {LoanContract.initLoanContract} for more details.
     *
     * @return _results true if the debt refinancing was successful.
     */
    function executeRefinancePurchase(
        uint256 _debtId,
        address _borrower,
        address _purchaser,
        bytes32 _contracTerms
    )
        external
        payable
        onlyRole(_DEBT_MARKET_)
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        returns (bool _results)
    {
        // Create loan contract for new lender
        (bool _success, ) = address(_loanContract).call{value: msg.value}(
            abi.encodeWithSignature(
                "initContract(uint256,address,address,bytes32)",
                _debtId,
                _borrower,
                _purchaser,
                _contracTerms
            )
        );
        if (!_success) revert StdTreasureyErrors.FailedPurchase();

        _results = true;
    }

    /**
     * A full transfer of debt sponsorship from the current lender to a new
     * lender.
     *
     * This function will keep the existing loan contract open and transfer
     * the sponsorship to a new lender.
     *
     * @notice This function does not apply a reentrancy guard since it does not
     * directly call a deposit. There is however a reentrancy guard further in
     * the call stack at LoanTreasury.sponsorPayment.
     *
     * @param _debtId The ID of the debt to be refinanced.
     * @param _purchaser The address of the new lender purchasing the debt
     * sponsorship.
     *
     * @dev Only the debt marketplace can execute this method.
     * @dev Only active debts can be refinanced.
     * @dev This function updates the debt prior to execution.
     * @dev This function is non-reentrant.
     *
     * See {LoanContract.initLoanContract} for more details.
     *
     * @return _results true if the debt refinancing was successful.
     */
    function executeSponsorshipPurchase(
        uint256 _debtId,
        address _purchaser
    )
        external
        payable
        onlyRole(_DEBT_MARKET_)
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        returns (bool _results)
    {
        // Create loan contract for new lender
        (bool _success, ) = address(_loanContract).call{value: msg.value}(
            abi.encodeWithSignature(
                "initContract(uint256,address,address)",
                _debtId,
                _anzaToken.borrowerOf(_debtId),
                _purchaser
            )
        );
        if (!_success) revert StdTreasureyErrors.FailedPurchase();

        _results = true;
    }

    /**
     * This function overrides the parent class to allow for refunds of
     * payments made to the loan contract if the update permit lock has not
     * been set.
     *
     * @notice If the payment is zero, this function will behave as normal,
     * The intention of this behavior is to allow conditions where a debt
     * transfer is conducted on collateral that has partially paid off loan
     * contracts.
     *
     * @param _payer The address of the account making the payment.
     * @param _debtId The ID of the debt being paid.
     * @param _payment The amount of the payment.
     *
     * See {PaymentBook._depositPayment} for more details.
     *
     * @return The amount of the payment that was not deposited.
     */
    function _depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) internal override returns (uint256) {
        // If any loan is expired for this collateral, do not allow
        // debt transfers.
        _loanManager.verifyLoanNotExpired(_debtId);

        // If loan is active, conduct payment deposit.
        if (_updatePermitted())
            return super._depositPayment(_payer, _debtId, _payment);

        return _payment;
    }

    /**
     * Wrapper function for _depositPayment that allows for the debt to be
     * updated prior to the payment being deposited.
     *
     * @param _payer The address of the account making the payment.
     * @param _debtId The ID of the debt being paid.
     * @param _payment The amount of the payment.
     *
     * @return The amount of the payment that was not deposited.
     */
    function __depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) private debtUpdater(_debtId) returns (uint256) {
        return _depositPayment(_payer, _debtId, _payment);
    }
}
