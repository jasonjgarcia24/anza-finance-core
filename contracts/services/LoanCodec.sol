// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@universal-numbers/StdNumbers.sol";
import "@lending-constants/LoanContractFIRIntervals.sol";
import "@lending-constants/LoanContractNumbers.sol";
import "@lending-constants/LoanContractTermMaps.sol";
import "@lending-constants/LoanContractStates.sol";
import {StdCodecErrors, _INVALID_LOAN_PARAMETER_SELECTOR_} from "@custom-errors/StdCodecErrors.sol";
import {_ILLEGAL_TERMS_UPDATE_SELECTOR_} from "@custom-errors/StdManagerErrors.sol";
import "@custom-errors/StdLoanErrors.sol";

import {ILoanCodec} from "@services-interfaces/ILoanCodec.sol";
import {ILoanManager} from "@services-interfaces/ILoanManager.sol";
import {DebtTerms} from "@lending-databases/DebtTerms.sol";
import {InterestCalculator as Interest} from "@lending-libraries/InterestCalculator.sol";

abstract contract LoanCodec is ILoanCodec, DebtTerms {
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(DebtTerms) returns (bool) {
        return
            DebtTerms.supportsInterface(_interfaceId) ||
            _interfaceId == type(ILoanCodec).interfaceId;
    }

    /**
     * Function to get the total fixed interest rate intervals passed since
     * the `_start` time.
     *
     * @param _debtId The debt ID of the loan.
     * @param _timeElapsed The time elapsed to calculate the total number of
     * FIR intervals.
     *
     * @return The total number of FIR intervals throughout the `_timeElapsed`
     * time.
     */
    function totalFirIntervals(
        uint256 _debtId,
        uint256 _timeElapsed
    ) public view returns (uint256) {
        // Return the total number of FIR intervals.
        return _getTotalFirIntervals(firInterval(_debtId), _timeElapsed);
    }

    function _validateLoanTerms(
        bytes32 _contractTerms,
        uint64 _loanStart,
        uint256 _principal
    ) internal pure {
        if (_principal == 0)
            revert StdCodecErrors.InvalidLoanParameter(_PRINCIPAL_ERROR_ID_);

        uint32 _duration;
        uint8 _fixedInterestRate;
        uint8 _firInterval;

        assembly {
            function __revert(_errId) {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _errId)
                revert(0x20, 0x08)
            }

            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            let _lenderRoyalties := and(mload(0), _UINT8_MAX_)

            if gt(_lenderRoyalties, 0x64) {
                __revert(_LENDER_ROYALTIES_ERROR_ID_)
            }

            // Get packed terms expiry
            mstore(0x1b, _contractTerms)
            let _termsExpiry := and(mload(0), _UINT32_MAX_)

            if lt(_termsExpiry, _SECONDS_PER_24_MINUTES_RATIO_SCALED_) {
                __revert(_TERMS_EXPIRY_ERROR_ID_)
            }

            // Get packed duration
            mstore(0x17, _contractTerms)
            _duration := and(mload(0), _UINT32_MAX_)

            if iszero(_duration) {
                __revert(_DURATION_ERROR_ID_)
            }

            // Get packed grace period
            mstore(0x13, _contractTerms)
            let _gracePeriod := and(mload(0), _UINT32_MAX_)

            // This will effectively eliminate flash loans.
            // TODO: Consider adding in an acceptable condition where both are
            // zero for flash loans.
            if iszero(lt(_gracePeriod, _duration)) {
                __revert(_GRACE_PERIOD_ERROR_ID_)
            }

            if gt(add(add(_loanStart, _duration), _gracePeriod), _UINT64_MAX_) {
                __revert(_DURATION_ERROR_ID_)
            }

            // Get fixed interest rate
            mstore(0x01, _contractTerms)
            _fixedInterestRate := and(mload(0), _UINT8_MAX_)

            // Get fir interval
            mstore(0x00, _contractTerms)
            _firInterval := and(mload(0), _UINT8_MAX_)

            if gt(_firInterval, 15) {
                __revert(_FIR_INTERVAL_ERROR_ID_)
            }
        }

        // Check max compounded debt
        try
            Interest.compoundWithTopoff(
                _principal,
                _fixedInterestRate,
                _getTotalFirIntervals(_firInterval, _duration)
            )
        returns (uint256) {} catch {
            if (_firInterval != 0)
                revert StdCodecErrors.InvalidLoanParameter(
                    _FIXED_INTEREST_RATE_ERROR_ID_
                );
        }
    }

    /**
     * Returns the total number of fir intervals in a given duration of seconds.
     *
     * @notice This function intentionally uses unsafe division.
     *
     * @param _firInterval The fir interval to use.
     * @param _seconds The duration in seconds.
     *
     * @dev Reverts if `_firInterval` is not a valid fir interval.
     *
     * See {LoanContractFIRIntervals} for valid fir intervals.
     *
     * @return _totalFirIntervals The total number of fir intervals.
     */
    function _getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) internal pure returns (uint256 _totalFirIntervals) {
        assembly {
            switch _firInterval
            // _SECONDLY_
            case 0 {
                _totalFirIntervals := _seconds
            }
            // _MINUTELY_
            case 1 {
                _totalFirIntervals := div(_seconds, _MINUTELY_MULTIPLIER_)
            }
            // _HOURLY_
            case 2 {
                _totalFirIntervals := div(_seconds, _HOURLY_MULTIPLIER_)
            }
            // _DAILY_
            case 3 {
                _totalFirIntervals := div(_seconds, _DAILY_MULTIPLIER_)
            }
            // _WEEKLY_
            case 4 {
                _totalFirIntervals := div(_seconds, _WEEKLY_MULTIPLIER_)
            }
            // _2_WEEKLY_
            case 5 {
                _totalFirIntervals := div(_seconds, _2_WEEKLY_MULTIPLIER_)
            }
            // _4_WEEKLY_
            case 6 {
                _totalFirIntervals := div(_seconds, _4_WEEKLY_MULTIPLIER_)
            }
            // _6_WEEKLY_
            case 7 {
                _totalFirIntervals := div(_seconds, _6_WEEKLY_MULTIPLIER_)
            }
            // _8_WEEKLY_
            case 8 {
                _totalFirIntervals := div(_seconds, _8_WEEKLY_MULTIPLIER_)
            }
            // _360_DAILY_
            case 14 {
                _totalFirIntervals := div(_seconds, _360_DAILY_MULTIPLIER_)
            }
            // Invalid fir interval
            default {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _FIR_INTERVAL_ERROR_ID_)
                revert(0x20, 0x08)
            }
        }
    }

    function _setLoanAgreement(
        uint64 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) internal {
        bytes32 _loanAgreement;

        assembly {
            function __packTerm(_mask, _map, _pos, _val) {
                mstore(
                    0x20,
                    xor(and(_mask, mload(0x20)), and(_map, shl(_pos, _val)))
                )
            }

            // Get packed fixed interest rate
            mstore(0x01, _contractTerms)
            let _fixedInterestRate := and(mload(0), _UINT8_MAX_)

            // Get packed is direct and commital
            // Need to mask other packed terms for gt
            // comparison below.
            mstore(0x02, _contractTerms)
            let _isDirect_Commital := and(mload(0), _UINT8_MAX_)

            // Get packed grace period
            mstore(0x13, _contractTerms)
            let _gracePeriod := and(mload(0), _UINT32_MAX_)

            // Get packed duration
            mstore(0x17, _contractTerms)
            let _duration := and(mload(0), _UINT32_MAX_)

            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            let _lenderRoylaties := and(mload(0), _UINT8_MAX_)

            // Shift left to make space for loan state
            mstore(0x20, shl(4, _contractTerms))

            // Pack loan state (uint4)
            switch iszero(_gracePeriod)
            case 1 {
                __packTerm(
                    _LOAN_STATE_MASK_,
                    _LOAN_STATE_MAP_,
                    _LOAN_STATE_POS_,
                    _ACTIVE_STATE_
                )
            }
            default {
                __packTerm(
                    _LOAN_STATE_MASK_,
                    _LOAN_STATE_MAP_,
                    _LOAN_STATE_POS_,
                    _ACTIVE_GRACE_STATE_
                )
            }

            // Pack fir interval (uint4)
            // Already performed and not needed.

            // Pack fixed interest rate (uint8)
            __packTerm(_FIR_MASK_, _FIR_MAP_, _FIR_POS_, _fixedInterestRate)

            // Pack loan start time (uint64)
            __packTerm(
                _LOAN_START_MASK_,
                _LOAN_START_MAP_,
                _LOAN_START_POS_,
                add(_now, _gracePeriod)
            )

            // Pack loan duration time (uint32)
            __packTerm(
                _LOAN_DURATION_MASK_,
                _LOAN_DURATION_MAP_,
                _LOAN_DURATION_POS_,
                sub(_duration, _gracePeriod)
            )

            switch gt(_isDirect_Commital, 0x64)
            case true {
                // Pack is direct (uint4) - true
                __packTerm(
                    _IS_FIXED_MASK_,
                    _IS_FIXED_MAP_,
                    _IS_FIXED_POS_,
                    0x01
                )

                // Pack commital (uint8)
                __packTerm(
                    _COMMITAL_MASK_,
                    _COMMITAL_MAP_,
                    _COMMITAL_POS_,
                    sub(_isDirect_Commital, 0x65)
                )
            }
            case false {
                // Pack is direct (uint4) - false
                __packTerm(
                    _IS_FIXED_MASK_,
                    _IS_FIXED_MAP_,
                    _IS_FIXED_POS_,
                    0x00
                )

                // Pack commital (uint8)
                __packTerm(
                    _COMMITAL_MASK_,
                    _COMMITAL_MAP_,
                    _COMMITAL_POS_,
                    _isDirect_Commital
                )
            }

            // Pack lender royalties (uint8)
            __packTerm(
                _LENDER_ROYALTIES_MASK_,
                _LENDER_ROYALTIES_MAP_,
                _LENDER_ROYALTIES_POS_,
                _lenderRoylaties
            )

            // Pack loan count (uint8)
            __packTerm(
                _LOAN_COUNT_MASK_,
                _LOAN_COUNT_MAP_,
                _LOAN_COUNT_POS_,
                _activeLoanIndex
            )

            _loanAgreement := and(_CLEANUP_MASK_, mload(0x20))
        }

        _setDebtTerms(_debtId, _loanAgreement);
    }

    function _setLoanAgreement(
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _sourceAgreement
    ) internal {
        bytes32 _loanAgreement;

        assembly {
            function __packTerm(_mask, _map, _pos, _val) {
                mstore(
                    0x20,
                    xor(and(_mask, mload(0x20)), and(_map, shl(_pos, _val)))
                )
            }

            mstore(0x20, _sourceAgreement)

            // Pack loan count (uint8)
            __packTerm(
                _LOAN_COUNT_MASK_,
                _LOAN_COUNT_MAP_,
                _LOAN_COUNT_POS_,
                _activeLoanIndex
            )

            _loanAgreement := and(_CLEANUP_MASK_, mload(0x20))
        }

        _setDebtTerms(_debtId, _loanAgreement);
    }

    function _updateLoanState(uint256 _debtId, uint8 _newLoanState) internal {
        bytes32 _contractTerms = debtTerms(_debtId);
        uint8 _oldLoanState;

        assembly {
            _oldLoanState := and(_LOAN_STATE_MAP_, _contractTerms)

            // If the loan states are the same or the new loan state is
            // greater than the max loan state, revert.
            if or(eq(_oldLoanState, _newLoanState), gt(_newLoanState, 0x0f)) {
                mstore(0x20, _ILLEGAL_TERMS_UPDATE_SELECTOR_)
                revert(0x20, 0x04)
            }

            mstore(0x20, _contractTerms)

            mstore(
                0x20,
                xor(
                    and(_LOAN_STATE_MASK_, mload(0x20)),
                    and(_LOAN_STATE_MAP_, _newLoanState)
                )
            )

            _contractTerms := mload(0x20)
        }

        _updateDebtTerms(_debtId, _contractTerms);

        emit LoanStateChanged(_debtId, _newLoanState, _oldLoanState);
    }

    /**
     * Updates the loan times.
     *
     * TODO: Need to account for grace periods.
     *
     * @param _debtId The debt id.
     */
    function _updateLoanTimes(uint256 _debtId) internal returns (uint256) {
        bytes32 _contractTerms = debtTerms(_debtId);

        assembly {
            // If loan state is beyond active, do nothing.
            if gt(and(_LOAN_STATE_MAP_, _contractTerms), _ACTIVE_STATE_) {
                mstore(0x20, _ILLEGAL_TERMS_UPDATE_SELECTOR_)
                revert(0x20, 0x04)
            }

            mstore(0x20, _contractTerms)

            // Store loan start time
            let _loanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )

            let _now := timestamp()
            if iszero(gt(_now, _loanStart)) {
                // Note: This will exit the current context entirely.
                // Therefore, we need to supply the loan state return
                // data directly.
                mstore(0x20, and(_LOAN_STATE_MAP_, _contractTerms))
                return(0x20, 0x20)
            }

            // Store loan close time
            let _loanClose := add(
                _loanStart,
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )

            if gt(_now, _loanClose) {
                _now := _loanClose
            }

            mstore(
                0x20,
                xor(
                    and(_LOAN_START_MASK_, mload(0x20)),
                    and(_LOAN_START_MAP_, shl(_LOAN_START_POS_, _now))
                )
            )

            mstore(
                0x20,
                xor(
                    and(_LOAN_DURATION_MASK_, mload(0x20)),
                    and(
                        _LOAN_DURATION_MAP_,
                        shl(_LOAN_DURATION_POS_, sub(_loanClose, _now))
                    )
                )
            )

            _contractTerms := mload(0x20)
        }

        _updateDebtTerms(_debtId, _contractTerms);

        return 1;
    }
}
