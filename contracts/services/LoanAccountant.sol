// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_} from "@lending-constants/LoanContractRoles.sol";
import {_UINT256_MAX_} from "@universal-numbers/StdNumbers.sol";

import {PaymentBook} from "@lending-databases/PaymentBook.sol";
import {AccountantAccessController} from "@lending-access/AccountantAccessController.sol";
import {InterestCalculator as Interest} from "@lending-libraries/InterestCalculator.sol";

abstract contract LoanAccountant is PaymentBook, AccountantAccessController {
    bool private __updatePermit;

    constructor() AccountantAccessController() {}

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
     * Ensures the __updatePermit flag is set to false prior to function
     * execution.
     *
     * @dev This modifier should be used in functions that modify the
     * __updatePermit flag.
     */
    modifier updatePermitLocker() {
        // Initialize the update permit flag to false
        __updatePermit = false;
        _;
    }

    /**
     * Updates the debt of the debt ID.
     *
     * @dev This modifier should be used in functions that perform
     * monetary operations and debt responsibility exchanges on debt.
     *
     * @notice This modifier calls the __updateDebt() function prior to
     * the modified function's execution. Within the __updateDebt() function,
     * the __updatePermit is conditionally set to true/false. If the flag
     * is set to true, the LoanManager will be called to update the loan
     * state. At the modifier's conclusion, the __updatePermit flag will
     * be reset to false.
     *
     * @param _debtId The debt ID to update.
     */
    modifier debtUpdater(uint256 _debtId) {
        __updateDebt(_debtId);
        _;
        if (__updatePermit) _loanManager.updateLoanState(_debtId);

        // Reset the update permit flag to false
        __updatePermit = false;
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

    /**
     * Internal access function for __updatePermit flag.
     *
     * @return The value of the __updatePermit flag.
     */
    function _updatePermitted() internal view returns (bool) {
        return __updatePermit;
    }

    function __assessUpdatePermitted(uint256 _debtId) internal {
        __updatePermit =
            !_loanManager.checkLoanExpired(_debtId) &&
            !_loanManager.checkLoanClosed(_debtId);
    }

    // TODO: Need to revisit to ensure accuracy at larger total debt values
    // (e.g. 10000 * 10**18).
    function __updateDebt(uint256 _debtId) private updatePermitLocker {
        uint256 _prevCheck = _loanDebtTerms.loanLastChecked(_debtId);

        // Update both the loan's state and the last checked timestamp.
        // If an update is performed the result will be less than 3.
        // If the loan is paid off, expired, or closed the result will
        // be 3, 4, type(uint256).max respectively.
        if (_loanManager.updateLoanState(_debtId) >= 3) {
            __assessUpdatePermitted(_debtId);
            return;
        }

        // Find time intervals passed
        uint256 _firIntervals = _loanCodec.totalFirIntervals(
            _debtId,
            _loanDebtTerms.loanLastChecked(_debtId) - _prevCheck
        );

        // Update debt if needed
        if (_firIntervals > 0) {
            uint256 _totalDebt = _anzaToken.totalSupply(_debtId * 2);

            uint256 _updatedDebt = Interest.compoundWithTopoff(
                _totalDebt,
                _loanDebtTerms.fixedInterestRate(_debtId),
                _firIntervals
            );

            _anzaToken.mint(_debtId, _updatedDebt - _totalDebt);
        }

        __assessUpdatePermitted(_debtId);

        console.log("Updated debt: %s", __updatePermit);
    }
}
