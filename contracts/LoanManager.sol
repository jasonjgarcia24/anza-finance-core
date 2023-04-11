// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./domain/LoanContractErrorCodes.sol";
import "./domain/LoanContractNumbers.sol";

import "./LoanCodec.sol";
import "./access/LoanAccessController.sol";
import "./interfaces/ILoanManager.sol";
import {LibLoanContractInterest as Interest} from "./libraries/LibLoanContract.sol";

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

    function setLoanTreasurer(
        address _loanTreasurer
    ) external onlyRole(Roles._ADMIN_) {
        __loanTreasurer = ILoanTreasurey(_loanTreasurer);
    }

    function setAnzaToken(
        address _anzaTokenAddress
    ) external onlyRole(Roles._ADMIN_) {
        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    function setMaxRefinances(
        uint256 _maxRefinances
    ) external onlyRole(Roles._ADMIN_) {
        maxRefinances = _maxRefinances <= 255 ? _maxRefinances : 2008;
    }

    /*
     * @dev Updates loan state.
     */
    function updateLoanState(
        uint256 _debtId
    ) external onlyRole(Roles._TREASURER_) {
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

    function _validateLoanTerms(
        bytes32 _contractTerms,
        uint32 _loanStart,
        uint256 _amount
    ) internal pure {
        uint8 _lenderRoyalties;
        uint32 _termsExpiry;
        uint32 _duration;
        uint32 _gracePeriod;
        uint128 _principal;
        uint8 _fixedInterestRate;
        uint8 _firInterval;

        assembly {
            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            _lenderRoyalties := mload(0)

            // Get packed terms expiry
            mstore(0x1b, _contractTerms)
            _termsExpiry := mload(0)

            // Get packed duration
            mstore(0x17, _contractTerms)
            _duration := mload(0)

            // Get packed grace period
            mstore(0x13, _contractTerms)
            _gracePeriod := mload(0)

            // Get packed principal
            mstore(0x03, _contractTerms)
            _principal := mload(0)

            // Get fixed interest rate
            mstore(0x01, _contractTerms)
            _fixedInterestRate := mload(0)

            // Get fir interval
            mstore(0x00, _contractTerms)
            _firInterval := mload(0)
        }

        unchecked {
            // Check lender royalties
            if (_lenderRoyalties > 100) {
                revert InvalidLoanParameter(_LENDER_ROYALTIES_ERROR_ID_);
            }

            // Check terms expiry
            if (_termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_) {
                revert InvalidLoanParameter(_TIME_EXPIRY_ERROR_ID_);
            }

            // Check duration and grace period
            if (
                uint256(_duration) == 0 ||
                (uint256(_loanStart) +
                    uint256(_duration) +
                    uint256(_gracePeriod)) >
                type(uint32).max
            ) {
                revert InvalidLoanParameter(_DURATION_ERROR_ID_);
            }

            // Check principal
            if (_principal == 0 || _principal != _amount)
                revert InvalidLoanParameter(_PRINCIPAL_ERROR_ID_);

            // No fixed interest rate check necessary

            // Check FIR interval
            if (_firInterval > 15)
                revert InvalidLoanParameter(_FIR_INTERVAL_ERROR_ID_);

            // Check max compounded debt
            try
                Interest.compoundWithTopoff(
                    _principal,
                    _fixedInterestRate,
                    _getTotalFirIntervals(_firInterval, _duration)
                )
            returns (uint256) {} catch {
                revert InvalidLoanParameter(_FIXED_INTEREST_RATE_ERROR_ID_);
            }
        }
    }
}
