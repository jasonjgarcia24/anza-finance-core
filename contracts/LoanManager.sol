// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./LoanCodec.sol";
import "./access/LoanAccessController.sol";
import "./interfaces/ILoanManager.sol";

contract LoanManager is ILoanManager, LoanCodec, LoanAccessController {
    // Max number of loan refinances (default is unlimited)
    uint256 public maxRefinances = 2008;

    ILoanTreasurey private __loanTreasurer;
    IAnzaToken internal _anzaToken;

    constructor(
        address _collateralVault
    ) LoanAccessController(_collateralVault) {}

    function loanTreasurer() public view returns (address) {
        return address(__loanTreasurer);
    }

    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    function setLoanTreasurer(address _loanTreasurer) external onlyRole(ADMIN) {
        __loanTreasurer = ILoanTreasurey(_loanTreasurer);
    }

    function setAnzaToken(address _anzaTokenAddress) external onlyRole(ADMIN) {
        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    function setMaxRefinances(uint256 _maxRefinances) external onlyRole(ADMIN) {
        maxRefinances = _maxRefinances <= 255 ? _maxRefinances : 2008;
    }

    /*
     * @dev Updates loan state.
     */
    function updateLoanState(uint256 _debtId) external onlyRole(TREASURER) {
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
        else if (_anzaToken.totalSupply(_debtId * 2) <= 0) {
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
            _anzaToken.totalSupply(_debtId * 2) > 0 &&
            loanClose(_debtId) <= block.timestamp;
    }

    function _checkGracePeriod(uint256 _debtId) internal view returns (bool) {
        return loanStart(_debtId) > block.timestamp;
    }
}
