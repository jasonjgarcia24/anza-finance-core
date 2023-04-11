// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "./domain/LoanContractFIRIntervals.sol";
import "./domain/LoanContractTermMaps.sol";
import "./domain/LoanContractStates.sol";

import "./interfaces/ILoanCodec.sol";

abstract contract LoanCodec is ILoanCodec {
    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );

    /**
     *  > 004 - [0..3]     `loanState`
     *  > 004 - [4..7]     `firInterval`
     *  > 008 - [8..15]    `fixedInterestRate`
     *  > 032 - [16..47]   `loanStart`
     *  > 032 - [48..79]   `loanDuration`
     *  > 160 - [80..239]  unused space
     *  > 008 - [240..247] `lenderRoyalties`
     *  > 008 - [248..255] `activeLoanIndex`
     */
    mapping(uint256 => bytes32) private __packedDebtTerms;

    function getDebtTerms(uint256 _debtId) external view returns (bytes32) {
        return __packedDebtTerms[_debtId];
    }

    function loanState(
        uint256 _debtId
    ) public view returns (uint256 _loanState) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __loanState;

        assembly {
            __loanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function firInterval(
        uint256 _debtId
    ) public view returns (uint256 _firInterval) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __firInterval;

        assembly {
            __firInterval := shr(
                _FIR_INTERVAL_POS_,
                and(_contractTerms, _FIR_INTERVAL_MAP_)
            )
        }

        unchecked {
            _firInterval = __firInterval;
        }
    }

    function fixedInterestRate(
        uint256 _debtId
    ) public view returns (uint256 _fixedInterestRate) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        bytes32 __fixedInterestRate;

        assembly {
            __fixedInterestRate := shr(
                _FIR_POS_,
                and(_contractTerms, _FIR_MAP_)
            )
        }

        unchecked {
            _fixedInterestRate = uint256(__fixedInterestRate);
        }
    }

    function loanLastChecked(uint256 _debtId) external view returns (uint256) {
        return loanStart(_debtId);
    }

    function loanStart(
        uint256 _debtId
    ) public view returns (uint256 _loanStart) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanStart;

        assembly {
            __loanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )
        }

        unchecked {
            _loanStart = __loanStart;
        }
    }

    function loanDuration(
        uint256 _debtId
    ) public view returns (uint256 _loanDuration) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanDuration;

        assembly {
            __loanDuration := shr(
                _LOAN_DURATION_POS_,
                and(_contractTerms, _LOAN_DURATION_MAP_)
            )
        }

        unchecked {
            _loanDuration = __loanDuration;
        }
    }

    function loanClose(
        uint256 _debtId
    ) public view returns (uint256 _loanClose) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanClose;

        assembly {
            __loanClose := add(
                shr(_LOAN_START_POS_, and(_contractTerms, _LOAN_START_MAP_)),
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function lenderRoyalties(
        uint256 _debtId
    ) public view returns (uint256 _lenderRoyalties) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];

        assembly {
            _lenderRoyalties := shr(
                _LENDER_ROYALTIES_POS_,
                and(_contractTerms, _LENDER_ROYALTIES_MAP_)
            )
        }
    }

    function activeLoanCount(
        uint256 _debtId
    ) public view returns (uint256 _activeLoanCount) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __activeLoanCount;

        assembly {
            __activeLoanCount := shr(
                _LOAN_COUNT_POS_,
                and(_contractTerms, _LOAN_COUNT_MAP_)
            )
        }

        unchecked {
            _activeLoanCount = __activeLoanCount;
        }
    }

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) public view returns (uint256) {
        uint256 _firInterval = firInterval(_debtId);
        uint256 _duration = loanDuration(_debtId);
        _seconds = _seconds <= _duration ? _seconds : _duration;

        return _getTotalFirIntervals(_firInterval, _seconds);
    }

    function _getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) internal pure returns (uint256) {
        // _SECONDLY_
        if (_firInterval == 0) {
            return _seconds;
        }
        // _MINUTELY_
        else if (_firInterval == 1) {
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
        uint32 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) internal {
        bytes32 _loanAgreement;

        assembly {
            // Get packed fixed interest rate
            mstore(0x01, _contractTerms)
            let _fixedInterestRate := mload(0)

            // Get packed is direct and commital
            mstore(0x02, _contractTerms)
            let _isDirect_Commital := mload(0)

            // Get packed grace period
            mstore(0x13, _contractTerms)
            let _gracePeriod := mload(0)

            // Get packed duration
            mstore(0x17, _contractTerms)
            let _duration := mload(0)

            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            let _lenderTerms := mload(0)

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

            // Pack loan start time (uint32)
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

            switch gt(_isDirect_Commital, 0x64)
            case true {
                // Pack is direct (uint4) - true
                mstore(
                    0x20,
                    xor(
                        and(_IS_DIRECT_MASK_, mload(0x20)),
                        and(_IS_DIRECT_MAP_, shl(_IS_DIRECT_POS_, 0x01))
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
                        and(_IS_DIRECT_MASK_, mload(0x20)),
                        and(_IS_DIRECT_MAP_, shl(_IS_DIRECT_POS_, 0x00))
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

            // Pack lender royalties (uint8)
            mstore(
                0x20,
                xor(
                    and(_LENDER_ROYALTIES_MASK_, mload(0x20)),
                    and(
                        _LENDER_ROYALTIES_MAP_,
                        shl(_LENDER_ROYALTIES_POS_, _lenderTerms)
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
            _loanAgreement := mload(0x20)
        }
        console.logBytes32(
            0x00192750003b5380000093a80000000000000000000003b53800643e16260ae5
        );
        console.logBytes32(_loanAgreement);

        __packedDebtTerms[_debtId] = _loanAgreement;
    }

    function _setLoanState(uint256 _debtId, uint8 _newLoanState) internal {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
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

        __packedDebtTerms[_debtId] = _contractTerms;

        emit LoanStateChanged(_debtId, _newLoanState, _oldLoanState);
    }

    function _updateLoanTimes(uint256 _debtId) internal {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];

        assembly {
            let _loanState := and(_LOAN_STATE_MAP_, _contractTerms)

            // If loan state is beyond active, do nothing
            if gt(_loanState, _ACTIVE_STATE_) {
                revert(0, 0)
            }

            mstore(0x20, _contractTerms)

            // Store loan close time
            let _loanClose := add(
                shr(16, and(_LOAN_START_MAP_, _contractTerms)),
                shr(48, and(_LOAN_DURATION_MAP_, _contractTerms))
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

        __packedDebtTerms[_debtId] = _contractTerms;
    }
}
