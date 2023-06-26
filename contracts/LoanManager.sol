// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_, _TREASURER_} from "@lending-constants/LoanContractRoles.sol";
import "@lending-constants/LoanContractStates.sol";
import {_MAX_REFINANCES_} from "@lending-constants/LoanContractNumbers.sol";
import {_UINT256_MAX_} from "@universal-numbers/StdNumbers.sol";
import {StdCodecErrors} from "@custom-errors/StdCodecErrors.sol";

import {ILoanManager} from "@lending-interfaces/ILoanManager.sol";
import {LoanCodec} from "@base/LoanCodec.sol";
import {DebtBook} from "@lending-databases/DebtBook.sol";
import {ManagerAccessController} from "@lending-access/ManagerAccessController.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract LoanManager is
    ILoanManager,
    LoanCodec,
    DebtBook,
    ManagerAccessController
{
    constructor() ManagerAccessController() {}

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(LoanCodec, DebtBook, ManagerAccessController)
        returns (bool)
    {
        return
            _interfaceId == type(ILoanManager).interfaceId ||
            LoanCodec.supportsInterface(_interfaceId) ||
            DebtBook.supportsInterface(_interfaceId) ||
            ManagerAccessController.supportsInterface(_interfaceId);
    }

    function maxRefinances() public pure returns (uint256) {
        return _MAX_REFINANCES_;
    }

    /**
     * Checked public call to set the Anza Token address.
     *
     * @notice This function fullfills the DebtBook signature.
     *
     * @param _anzaToken The Anza Token address.
     *
     * @dev This function is only callable by the _ADMIN_ role.
     */
    function setAnzaToken(
        address _anzaToken
    ) public override onlyRole(_ADMIN_) {
        super._setAnzaToken(_anzaToken);
    }

    /**
     * Checked public call to set the Collateral Vault address.
     *
     * @notice This function fullfills the DebtBook signature.
     *
     * @param _collateralVault The Collateral Vault address.
     *
     * @dev This function is only callable by the _ADMIN_ role.
     */
    function setCollateralVault(
        address _collateralVault
    ) public override onlyRole(_ADMIN_) {
        super._setCollateralVault(_collateralVault);
    }

    /**
     * Updates the loan state and times.
     *
     * This funcion conducts updates per the following conditions:
     *  > If the loan is in an expired state, the loan times are updated and
     *    the loan state is set to _DEFAULT_STATE_.
     *  > If the loan is fully paid off, the loan state is set to _PAID_STATE_.
     *  > If the loan is active and interest is accruing, the loan times are
     *    updated.
     *  > If the loan is currently in _ACTIVE_GRACE_STATE_ and the grace period
     *    has expired, the loan state is transitioned to _ACTIVE_STATE_ and the
     *    loan times are updated.
     *
     * @param _debtId The debt id.
     *
     * @dev This function is only callable by the _TREASURER_ role.
     * @dev This function is only callable when the loan is active or closed
     * (i.e. not in an inactive state).
     *
     * @return True if the loan remains active, false otherwise.
     */
    function updateLoanState(
        uint256 _debtId
    ) external onlyRole(_TREASURER_) returns (uint256) {
        if (checkLoanClosed(_debtId)) {
            console.log("Closed loan: %s", _debtId);
            return _UINT256_MAX_;
        }

        if (!checkLoanActive(_debtId)) {
            console.log("Inactive loan: %s", _debtId);
            revert StdCodecErrors.InactiveLoanState();
        }

        // Loan defaulted
        if (checkLoanExpired(_debtId)) {
            console.log("Defaulted loan: %s", _debtId);
            _updateLoanTimes(_debtId, 4);
            _updateLoanState(_debtId, _DEFAULT_STATE_);
            return 4;
        }
        // Loan fully paid off
        else if (debtBalance(_debtId) <= 0) {
            console.log("Paid loan: %s", _debtId);
            _updateLoanState(_debtId, _PAID_STATE_);
            return 3;
        }
        // Loan active and interest compounding
        else if (loanState(_debtId) == _ACTIVE_STATE_) {
            console.log("Active loan: %s", _debtId);
            _updateLoanTimes(_debtId, 2);
            return 2;
        }
        // Loan no longer in grace period
        else if (!_checkLoanGracePeriod(_debtId)) {
            console.log("Grace period expired: %s", _debtId);
            _updateLoanState(_debtId, _ACTIVE_STATE_);
            _updateLoanTimes(_debtId, 2);
            return 2;
        } else if (_checkLoanGracePeriod(_debtId)) {
            console.log("Grace period ongoing: %s", _debtId);
            return 1;
        }

        return 0;
    }

    function verifyLoanActive(uint256 _debtId) public view {
        if (!checkLoanActive(_debtId))
            revert StdCodecErrors.InactiveLoanState();
    }

    function verifyLoanNotExpired(uint256 _debtId) public view {
        if (checkLoanExpired(_debtId)) revert StdCodecErrors.ExpriredLoan();
    }

    function checkProposalActive(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce
    ) public view returns (bool) {
        uint256 _nextCollateralNonce = collateralNonce(
            _collateralAddress,
            _collateralId
        );

        return _nextCollateralNonce <= _collateralNonce;
    }

    function checkLoanActive(uint256 _debtId) public view returns (bool) {
        return
            loanState(_debtId) >= _ACTIVE_GRACE_STATE_ &&
            loanState(_debtId) <= _ACTIVE_STATE_;
    }

    function checkLoanDefault(uint256 _debtId) public view returns (bool) {
        return
            loanState(_debtId) >= _DEFAULT_STATE_ &&
            loanState(_debtId) <= _AWARDED_STATE_;
    }

    function checkLoanClosed(uint256 _debtId) public view returns (bool) {
        return loanState(_debtId) >= _PAID_PENDING_STATE_;
    }

    function checkLoanExpired(uint256 _debtId) public view returns (bool) {
        return
            debtBalance(_debtId) > 0 && loanClose(_debtId) <= block.timestamp;
    }

    function _checkLoanGracePeriod(
        uint256 _debtId
    ) internal view returns (bool) {
        return loanStart(_debtId) > block.timestamp;
    }
}
