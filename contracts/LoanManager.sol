// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_, _TREASURER_} from "@lending-constants/LoanContractRoles.sol";
import {_DEFAULT_STATE_, _PAID_STATE_, _ACTIVE_STATE_, _ACTIVE_GRACE_STATE_, _AWARDED_STATE_, _CLOSE_STATE_} from "@lending-constants/LoanContractStates.sol";
import {StdCodecErrors} from "@custom-errors/StdCodecErrors.sol";

import {ILoanManager} from "@lending-interfaces/ILoanManager.sol";
import {LoanCodec} from "./LoanCodec.sol";
import {DebtBook} from "@lending-databases/DebtBook.sol";
import {ManagerAccessController} from "@lending-access/ManagerAccessController.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract LoanManager is
    ILoanManager,
    LoanCodec,
    DebtBook,
    ManagerAccessController
{
    // Max number of loan refinances (default is unlimited)
    uint256 public maxRefinances = 2008;

    // TODO: This should be pulled into a LoanValidator or the LoanCodec contract.
    mapping(address => mapping(bytes32 => bool)) private __revokedTerms;

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

    function setMaxRefinances(
        uint256 _maxRefinances
    ) external onlyRole(_ADMIN_) {
        maxRefinances = _maxRefinances <= 255 ? _maxRefinances : 2008;
    }

    function setAnzaToken(address _anzaToken) external onlyRole(_ADMIN_) {
        _setAnzaToken(_anzaToken);
    }

    function setCollateralVault(
        address _collateralVault
    ) external onlyRole(_ADMIN_) {
        _setCollateralVault(_collateralVault);
    }

    /*
     * @dev Updates loan state.
     */
    function updateLoanState(uint256 _debtId) external onlyRole(_TREASURER_) {
        if (checkLoanClosed(_debtId)) {
            console.log("Closed loan: %s", _debtId);
            return;
        }

        if (!checkLoanActive(_debtId)) {
            console.log("Inactive loan: %s", _debtId);
            revert StdCodecErrors.InactiveLoanState();
        }

        // Loan defaulted
        if (checkLoanExpired(_debtId)) {
            console.log("Defaulted loan: %s", _debtId);
            _updateLoanTimes(_debtId);
            _setLoanState(_debtId, _DEFAULT_STATE_);
        }
        // Loan fully paid off
        else if (debtBalance(_debtId) <= 0) {
            console.log("Paid loan: %s", _debtId);
            _setLoanState(_debtId, _PAID_STATE_);
        }
        // Loan active and interest compounding
        else if (loanState(_debtId) == _ACTIVE_STATE_) {
            console.log("Active loan: %s", _debtId);
            _updateLoanTimes(_debtId);
        }
        // Loan no longer in grace period
        else if (!_checkGracePeriod(_debtId)) {
            console.log("Grace period expired: %s", _debtId);
            _setLoanState(_debtId, _ACTIVE_STATE_);
            _updateLoanTimes(_debtId);
        }
    }

    function verifyLoanActive(uint256 _debtId) public view {
        if (!checkLoanActive(_debtId))
            revert StdCodecErrors.InactiveLoanState();
    }

    function checkTermsRevoked(
        address _borrower,
        bytes32 _hashedTerms
    ) public view returns (bool) {
        return __revokedTerms[_borrower][_hashedTerms];
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

    function checkLoanExpired(uint256 _debtId) public view returns (bool) {
        return
            debtBalance(_debtId) > 0 && loanClose(_debtId) <= block.timestamp;
    }

    function checkLoanClosed(uint256 _debtid) public view returns (bool) {
        return loanState(_debtid) >= _CLOSE_STATE_;
    }

    function revokeTerms(bytes32 _hashedTerms) public {
        __revokedTerms[msg.sender][_hashedTerms] = true;

        emit LoanTermsRevoked(msg.sender, _hashedTerms);
    }

    function reinstateTerms(bytes32 _hashedTerms) public {
        __revokedTerms[msg.sender][_hashedTerms] = false;

        emit LoanTermsReinstated(msg.sender, _hashedTerms);
    }

    function _checkGracePeriod(uint256 _debtId) internal view returns (bool) {
        return loanStart(_debtId) > block.timestamp;
    }
}
