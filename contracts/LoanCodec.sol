// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@universal-numbers/StdNumbers.sol";
import "@lending-constants/LoanContractFIRIntervals.sol";
import "@lending-constants/LoanContractNumbers.sol";
import "@lending-constants/LoanContractTermMaps.sol";
import "@lending-constants/LoanContractStates.sol";
import {StdCodecErrors, _INVALID_LOAN_PARAMETER_SELECTOR_} from "@custom-errors/StdCodecErrors.sol";
import {_FIR_INTERVAL_ERROR_ID_, _DURATION_ERROR_ID_, _PRINCIPAL_ERROR_ID_, _FIXED_INTEREST_RATE_ERROR_ID_, _TIME_EXPIRY_ERROR_ID_, _LENDER_ROYALTIES_ERROR_ID_} from "@custom-errors/StdLoanErrors.sol";

import {ILoanCodec} from "@lending-interfaces/ILoanCodec.sol";
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

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) public view returns (uint256) {
        _seconds = (_seconds + loanLastChecked(_debtId)) <= loanClose(_debtId)
            ? _seconds
            : loanDuration(_debtId);

        return _getTotalFirIntervals(firInterval(_debtId), _seconds);
    }

    function _validateLoanTerms(
        bytes32 _contractTerms,
        uint64 _loanStart,
        uint256 _principal
    ) internal view {
        if (_principal == 0)
            revert StdCodecErrors.InvalidLoanParameter(_PRINCIPAL_ERROR_ID_);

        uint32 _duration;
        uint8 _fixedInterestRate;
        uint8 _firInterval;

        assembly {
            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            let _lenderRoyalties := and(mload(0), _UINT8_MAX_)

            if gt(_lenderRoyalties, 100) {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _LENDER_ROYALTIES_ERROR_ID_)
                revert(0x20, 0x08)
            }

            // Get packed terms expiry
            mstore(0x1b, _contractTerms)
            let _termsExpiry := and(mload(0), _UINT32_MAX_)

            if lt(_termsExpiry, _SECONDS_PER_24_MINUTES_RATIO_SCALED_) {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _TIME_EXPIRY_ERROR_ID_)
                revert(0x20, 0x08)
            }

            // Get packed duration
            mstore(0x17, _contractTerms)
            _duration := and(mload(0), _UINT32_MAX_)

            if iszero(_duration) {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _DURATION_ERROR_ID_)
                revert(0x20, 0x08)
            }

            // Get packed grace period
            mstore(0x13, _contractTerms)
            let _gracePeriod := and(mload(0), _UINT32_MAX_)

            if gt(add(add(_loanStart, _duration), _gracePeriod), _UINT32_MAX_) {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _DURATION_ERROR_ID_)
                revert(0x20, 0x08)
            }

            // Get fixed interest rate
            mstore(0x01, _contractTerms)
            _fixedInterestRate := and(mload(0), _UINT8_MAX_)

            // Get fir interval
            mstore(0x00, _contractTerms)
            _firInterval := and(mload(0), _UINT8_MAX_)

            if gt(_firInterval, 15) {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _FIR_INTERVAL_ERROR_ID_)
                revert(0x20, 0x08)
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

    function _getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) internal view returns (uint256) {
        // _SECONDLY_
        if (_firInterval == 0) {
            return _seconds;
        }
        // _MINUTELY_
        else if (_firInterval == 1) {
            console.log("Seconds: %s", _seconds);
            console.log("Minutely Multiplier: %s", _MINUTELY_MULTIPLIER_);

            return _seconds / _MINUTELY_MULTIPLIER_;
        }
        // _HOURLY_
        else if (_firInterval == 2) {
            return _seconds / _HOURLY_MULTIPLIER_;
        }
        // _DAILY_
        else if (_firInterval == 3) {
            return _seconds / _DAILY_MULTIPLIER_;
        }
        // _WEEKLY_
        else if (_firInterval == 4) {
            return _seconds / _WEEKLY_MULTIPLIER_;
        }
        // _2_WEEKLY_
        else if (_firInterval == 5) {
            return _seconds / _2_WEEKLY_MULTIPLIER_;
        }
        // _4_WEEKLY_
        else if (_firInterval == 6) {
            return _seconds / _4_WEEKLY_MULTIPLIER_;
        }
        // _6_WEEKLY_
        else if (_firInterval == 7) {
            return _seconds / _6_WEEKLY_MULTIPLIER_;
        }
        // _8_WEEKLY_
        else if (_firInterval == 8) {
            return _seconds / _8_WEEKLY_MULTIPLIER_;
        }
        // _360_DAILY_
        else if (_firInterval == 14) {
            return _seconds / _360_DAILY_MULTIPLIER_;
        }

        return 0;
    }

    function _setLoanAgreement(
        uint64 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) internal virtual {
        bytes32 _loanAgreement;

        assembly {
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

            // Shif left to make space for loan state
            mstore(0x20, shl(4, _contractTerms))

            // Pack loan state (uint4)
            switch _gracePeriod
            case 0 {
                mstore(
                    0x20,
                    xor(
                        and(_LOAN_STATE_MASK_, mload(0x20)),
                        and(_LOAN_STATE_MAP_, _ACTIVE_STATE_)
                    )
                )
            }
            default {
                mstore(
                    0x20,
                    xor(
                        and(_LOAN_STATE_MASK_, mload(0x20)),
                        and(_LOAN_STATE_MAP_, _ACTIVE_GRACE_STATE_)
                    )
                )
            }

            // Pack fir interval (uint4)
            // Already performed and not needed.

            // Pack fixed interest rate (uint8)
            mstore(
                0x20,
                xor(
                    and(_FIR_MASK_, mload(0x20)),
                    and(_FIR_MAP_, shl(_FIR_POS_, _fixedInterestRate))
                )
            )

            // Pack loan start time (uint64)
            mstore(
                0x20,
                xor(
                    and(_LOAN_START_MASK_, mload(0x20)),
                    and(
                        _LOAN_START_MAP_,
                        shl(_LOAN_START_POS_, add(_now, _gracePeriod))
                    )
                )
            )

            // Pack loan duration time (uint32)
            mstore(
                0x20,
                xor(
                    and(_LOAN_DURATION_MASK_, mload(0x20)),
                    and(
                        _LOAN_DURATION_MAP_,
                        shl(_LOAN_DURATION_POS_, _duration)
                    )
                )
            )

            switch gt(_isDirect_Commital, 0x64)
            case true {
                // Pack is direct (uint4) - true
                mstore(
                    0x20,
                    xor(
                        and(_IS_FIXED_MASK_, mload(0x20)),
                        and(_IS_FIXED_MAP_, shl(_IS_FIXED_POS_, 0x01))
                    )
                )

                // Pack commital (uint8)
                mstore(
                    0x20,
                    xor(
                        and(_COMMITAL_MASK_, mload(0x20)),
                        and(
                            _COMMITAL_MAP_,
                            shl(_COMMITAL_POS_, sub(_isDirect_Commital, 0x65))
                        )
                    )
                )
            }
            case false {
                // Pack is direct (uint4) - false
                mstore(
                    0x20,
                    xor(
                        and(_IS_FIXED_MASK_, mload(0x20)),
                        and(_IS_FIXED_MAP_, shl(_IS_FIXED_POS_, 0x00))
                    )
                )

                // Pack commital (uint8)
                mstore(
                    0x20,
                    xor(
                        and(_COMMITAL_MASK_, mload(0x20)),
                        and(
                            _COMMITAL_MAP_,
                            shl(_COMMITAL_POS_, _isDirect_Commital)
                        )
                    )
                )
            }

            // Pack lender royalties (uint8)
            mstore(
                0x20,
                xor(
                    and(_LENDER_ROYALTIES_MASK_, mload(0x20)),
                    and(
                        _LENDER_ROYALTIES_MAP_,
                        shl(_LENDER_ROYALTIES_POS_, _lenderRoylaties)
                    )
                )
            )

            // Pack loan count (uint8)
            mstore(
                0x20,
                xor(
                    and(_LOAN_COUNT_MASK_, mload(0x20)),
                    and(
                        _LOAN_COUNT_MAP_,
                        shl(_LOAN_COUNT_POS_, _activeLoanIndex)
                    )
                )
            )

            _loanAgreement := and(_CLEANUP_MASK_, mload(0x20))
        }

        _setDebtTerms(_debtId, _loanAgreement);
    }

    function _setLoanState(uint256 _debtId, uint8 _newLoanState) internal {
        bytes32 _contractTerms = debtTerms(_debtId);
        uint8 _oldLoanState;

        assembly {
            _oldLoanState := and(_LOAN_STATE_MAP_, _contractTerms)

            // If the loan states are the same, do nothing
            if eq(_oldLoanState, _newLoanState) {
                revert(0, 0)
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

        _setDebtTerms(_debtId, _contractTerms);

        emit LoanStateChanged(_debtId, _newLoanState, _oldLoanState);
    }

    function _updateLoanTimes(uint256 _debtId) internal {
        bytes32 _contractTerms = debtTerms(_debtId);

        assembly {
            let _loanState := and(_LOAN_STATE_MAP_, _contractTerms)

            // If loan state is beyond active, do nothing
            if gt(_loanState, _ACTIVE_STATE_) {
                revert(0, 0)
            }

            mstore(0x20, _contractTerms)

            // Store loan close time
            let _loanClose := add(
                shr(_LOAN_START_POS_, and(_LOAN_START_MAP_, _contractTerms)),
                shr(
                    _LOAN_DURATION_POS_,
                    and(_LOAN_DURATION_MAP_, _contractTerms)
                )
            )

            let _now := timestamp()
            if gt(_now, _loanClose) {
                _now := _loanClose
            }

            // Update loan last checked. This could be a transition from
            // loan start to loan last checked if it is the first time this
            // condition is executed.
            mstore(
                0x20,
                xor(
                    and(_LOAN_START_MASK_, mload(0x20)),
                    and(_LOAN_START_MAP_, shl(16, _now))
                )
            )

            // Update loan duration
            mstore(
                0x20,
                xor(
                    and(_LOAN_DURATION_MASK_, mload(0x20)),
                    and(_LOAN_DURATION_MAP_, shl(48, sub(_loanClose, _now)))
                )
            )

            _contractTerms := mload(0x20)
        }

        _setDebtTerms(_debtId, _contractTerms);
    }
}
