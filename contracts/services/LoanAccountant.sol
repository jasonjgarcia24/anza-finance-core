// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_PAID_STATE_} from "@lending-constants/LoanContractStates.sol";

import {ILoanManager} from "@services-interfaces/ILoanManager.sol";
import {PaymentBook} from "@lending-databases/PaymentBook.sol";
import {AccountantAccessController} from "@lending-access/AccountantAccessController.sol";
import {InterestCalculator as Interest} from "@lending-libraries/InterestCalculator.sol";

abstract contract LoanAccountant is PaymentBook, AccountantAccessController {
    bool private __updatePermitted;

    constructor() AccountantAccessController() {}

    /**
     * Modifier to proceed the execution of a function with a loan state update
     * and a debt update, conditionally execute the function if the loan
     * state is valid for update, and conclude with a second loan state update
     * following the modified function's execution.
     *
     * @dev This modifier should be used in functions that perform
     * monetary operations and debt responsibility exchanges on debt.
     *
     * @notice This modifier calls the __updateDebtWithInterest() function
     * prior to the modified function's execution. Within the
     * __updateDebtWithInterest() function, the __updatePermitted is
     * conditionally set to true/false. If the flag is set to true, the
     * LoanManager will be called to update the loan state. At the modifier's
     * conclusion, the __updatePermitted flag will be reset to false.
     *
     * @notice This modifier does NOT revert when the __updateDebtWithInterest
     * function sets the __updatePermitted flag to false. The modified function
     * should handle the behavior of the remaining execution if it is reliant
     * on the __updatePermitted flag's status.
     *
     * @param _debtId The debt ID of the debt terms to update.
     */
    modifier debtUpdater(uint256 _debtId) {
        // Enable the update permit flag.
        __updatePermitted = true;

        // Get the last instance when the debt was updated prior to the
        // __updateLoanState() call.
        uint256 _lastChecked = _loanDebtTerms.loanLastChecked(_debtId);

        // Update loan.
        if (__updateLoanState(_debtId) < _PAID_STATE_) {
            // Update debt via minting of AnzaTokens.
            __updateDebtWithInterest(_debtId, _lastChecked);

            // Execute the modified function.
            _;

            // Update the loan to reflect the new state as a
            // result of the modified function's execution.
            __updateLoanState(_debtId);
        }

        // Reset the update permit flag to false
        __updatePermitted = false;
    }

    /**
     * Manages the locking of the update permit flag.
     *
     * @notice This modifier ensures the __updatePermitted flag is set to false
     * prior to function execution. It then performs a deterministic assessment
     * of the flag's status following the modified function's execution.
     *
     * @dev This modifier should be used on functions that modify the
     * __updatePermitted flag when the function's visibility is beyond this
     * contract's scope.
     */
    modifier updatePermittedLocker(uint256 _debtId) {
        // Initialize the update permit flag to false.
        __updatePermitted = false;
        _;
        // Determine the status of the update permit flag.
        __assessUpdatePermitted(_debtId);
    }

    /**
     * Ensures the debt is active.
     *
     * @dev This modifier should be used in functions that require the
     * debt to be active.
     *
     * @param _debtId The debt ID to verify.
     */
    modifier onlyActiveLoan(uint256 _debtId) {
        _loanManager.verifyLoanActive(_debtId);
        _;
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(PaymentBook, AccountantAccessController)
        returns (bool)
    {
        return
            PaymentBook.supportsInterface(_interfaceId) ||
            AccountantAccessController.supportsInterface(_interfaceId);
    }

    /**
     * Internal access function for __updatePermitted flag.
     *
     * @return The value of the __updatePermitted flag.
     */
    function _updatePermitted() internal view returns (bool) {
        return __updatePermitted;
    }

    /**
     * Private function to assess and set the update permit flag.
     *
     * @dev This function is called by the updatePermittedLocker() modifier.
     *
     * @param _debtId The debt ID to verify.
     */
    function __assessUpdatePermitted(uint256 _debtId) internal {
        __updatePermitted =
            !_loanManager.checkLoanExpired(_debtId) &&
            !_loanManager.checkLoanClosed(_debtId);
    }

    /**
     * Private function to update the loan state of the debt.
     *
     * @dev This function is called by the debtUpdater() modifier to update
     * the loan state of the debt ID. It is only called when the __updatePermitted
     * flag is set to true.
     *
     * @param _debtId The debt ID of the debt terms to update.
     *
     * @return The updated loan state of the debt ID.
     */
    function __updateLoanState(uint256 _debtId) private returns (uint8) {
        if (__updatePermitted) return _loanManager.updateLoanState(_debtId);

        unchecked {
            return uint8(_loanDebtTerms.loanState(_debtId));
        }
    }

    /**
     * Private function to Add debt to the debt ID.
     *
     * This function implements "lazy" compounding interest. In other words,
     * accrual is performed only when a transaction that requires the current prinicial
     * balance is invoked.
     *
     * TODO: Need to revisit to ensure accuracy at larger total debt values
     * (e.g. 10000 * 10**18).
     *
     * @dev This function is called by the debtUpdater() modifier to update
     * the debt of the debt ID. It is only called when the loan state is not
     * PAID. The function will update the debt of the debt ID by calculating
     * the interest accrued since the last time (`_start`)the debt was updated.
     *
     * @notice This function is modified with the updatePermittedLocker(). The
     * updatePermittedLocker() modifier ensures the __updatePermitted flag is
     * set to false prior to function execution. It then performs a deterministic
     * assessment of the flag's status following the function's execution.
     *
     * @param _debtId The debt ID of the debt terms to update.
     * @param _loanLastChecked The start time to calculate the interest accrued since.
     */
    function __updateDebtWithInterest(
        uint256 _debtId,
        uint256 _loanLastChecked
    ) private updatePermittedLocker(_debtId) {
        if (block.timestamp <= _loanLastChecked) return;

        // Find time intervals passed.
        uint256 _firIntervals = _loanCodec.totalFirIntervals(
            _debtId,
            block.timestamp - _loanLastChecked
        );
        uint256 _fixedInterestRate = _loanDebtTerms.fixedInterestRate(_debtId);

        // If intervals passed, update the debt.
        if (_firIntervals > 0 && _fixedInterestRate > 0) {
            uint256 _totalDebt = _loanContract.debtBalance(_debtId);

            // Calculate the updated debt.
            uint256 _newDebt = Interest.compound(
                _totalDebt,
                _fixedInterestRate,
                _firIntervals
            ) - _totalDebt;

            // Update the debt balance.
            if (_newDebt > 0) _anzaToken.mint(_debtId, _newDebt);
        }
    }
}
