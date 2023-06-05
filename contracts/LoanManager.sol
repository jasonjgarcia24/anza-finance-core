// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/ILoanManager.sol";
import "./LoanCodec.sol";
import "./access/ManagerAccessController.sol";

abstract contract LoanManager is
    ILoanManager,
    LoanCodec,
    ManagerAccessController
{
    // Max number of loan refinances (default is unlimited)
    uint256 public maxRefinances = 2008;

    mapping(address => mapping(bytes32 => bool)) private __revokedTerms;

    constructor() ManagerAccessController() {}

    function setMaxRefinances(
        uint256 _maxRefinances
    ) external onlyRole(_ADMIN_) {
        maxRefinances = _maxRefinances <= 255 ? _maxRefinances : 2008;
    }

    /*
     * @dev Updates loan state.
     */
    function updateLoanState(uint256 _debtId) external onlyRole(_TREASURER_) {
        if (!checkLoanActive(_debtId)) {
            console.log("Inactive loan: %s", _debtId);
            revert InactiveLoanState();
        }

        // Loan defaulted
        if (checkLoanExpired(_debtId)) {
            console.log("Defaulted loan: %s", _debtId);
            _updateLoanTimes(_debtId);
            _setLoanState(_debtId, _DEFAULT_STATE_);
        }
        // Loan fully paid off
        else if (
            _anzaToken.totalSupply(_anzaToken.lenderTokenId(_debtId)) <= 0
        ) {
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
        if (!checkLoanActive(_debtId)) revert InactiveLoanState();
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
            _anzaToken.totalSupply(_anzaToken.lenderTokenId(_debtId)) > 0 &&
            loanClose(_debtId) <= block.timestamp;
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
