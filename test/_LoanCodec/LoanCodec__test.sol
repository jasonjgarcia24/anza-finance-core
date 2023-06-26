// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractNumbers.sol";
import "@lending-constants/LoanContractStates.sol";
import "@lending-constants/LoanContractFIRIntervals.sol";
import "@custom-errors/StdLoanErrors.sol";
import "@custom-errors/StdCodecErrors.sol";
import {_ILLEGAL_TERMS_UPDATE_SELECTOR_} from "@custom-errors/StdManagerErrors.sol";

import {LoanCodec} from "@base/LoanCodec.sol";
import {ILoanCodec} from "@lending-interfaces/ILoanCodec.sol";
import {IDebtTerms} from "@lending-databases/interfaces/IDebtTerms.sol";
import {_OVERFLOW_CAST_SELECTOR_} from "@base/libraries/TypeUtils.sol";
import {InterestCalculator as Interest} from "@lending-libraries/InterestCalculator.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {DebtTermsUtils} from "@test-databases/DebtTerms__test.sol";
import {ILoanCodecEvents} from "./interfaces/ILoanCodecEvents__test.sol";

contract LoanCodecHarness is LoanCodec {
    function exposed__validateLoanTerms(
        bytes32 _contractTerms,
        uint64 _loanStart,
        uint256 _principal
    ) public pure {
        _validateLoanTerms(_contractTerms, _loanStart, _principal);
    }

    function exposed__getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) public pure returns (uint256) {
        return _getTotalFirIntervals(_firInterval, _seconds);
    }

    function exposed__setLoanAgreement(
        uint64 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) public {
        _setLoanAgreement(_now, _debtId, _activeLoanIndex, _contractTerms);
    }

    function exposed__updateLoanState(
        uint256 _debtId,
        uint8 _newLoanState
    ) public {
        _updateLoanState(_debtId, _newLoanState);
    }

    function exposed__updateLoanTimes(
        uint256 _debtId,
        uint256 _updateType
    ) public {
        _updateLoanTimes(_debtId, _updateType);
    }

    /* Abstract functions */
    /* ^^^^^^^^^^^^^^^^^^ */
}

interface ILoanCodecHarness is ILoanCodec, IDebtTerms {
    function exposed__validateLoanTerms(
        bytes32 _contractTerms,
        uint64 _loanStart,
        uint256 _principal
    ) external pure;

    function exposed__getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) external pure returns (uint256);

    function exposed__setLoanAgreement(
        uint64 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) external;

    function exposed__updateLoanState(
        uint256 _debtId,
        uint8 _newLoanState
    ) external;

    function exposed__updateLoanTimes(
        uint256 _debtId,
        uint256 _updateType
    ) external;
}

abstract contract LoanCodecInit is Setup {
    LoanCodecHarness public loanCodecHarness;
    DebtTermsUtils public debtTermsUtils;

    function setUp() public virtual override {
        super.setUp();

        // Deploy LoanCodecHarness.
        loanCodecHarness = new LoanCodecHarness();

        // Deploy DebtTermsUtils.
        debtTermsUtils = new DebtTermsUtils();
    }

    function cleanContractTerms(
        ContractTerms memory _contractTerms
    ) public view {
        // Only allow valid fir intervals.
        vm.assume(
            _contractTerms.firInterval <= 8 || _contractTerms.firInterval == 14
        );

        // Duration must be greater than grace period.
        vm.assume(_contractTerms.duration >= _contractTerms.gracePeriod);

        // Commital must be no greater than 100%.
        _contractTerms.commital = uint8(bound(_contractTerms.commital, 0, 100));

        // Lender royalties must be no greater than 100%.
        _contractTerms.lenderRoyalties = uint8(
            bound(_contractTerms.lenderRoyalties, 0, 100)
        );
    }
}

contract LoanCodecUtils is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    /**
     * Utility function to establish the expected contract terms validity.
     *
     * @param _contractTerms The contract terms to validate.
     * @param _loanContractHarness The LoanContract harness to call the
     * exposed__getTotalFirIntervals function.
     * @param _loanStart The loan start time.
     *
     * @return (bool, bytes memory) The validity and error message.
     */
    function expectedContractTermsValidity(
        ContractTerms memory _contractTerms,
        LoanCodecHarness _loanContractHarness,
        uint64 _loanStart
    ) public pure returns (bool, bytes memory) {
        // Principal revert check
        if (_contractTerms.principal == 0) {
            return (
                false,
                abi.encodePacked(
                    _INVALID_LOAN_PARAMETER_SELECTOR_,
                    _PRINCIPAL_ERROR_ID_
                )
            );
        }
        // Lender royalties revert check
        else if (_contractTerms.lenderRoyalties > 100) {
            return (
                false,
                abi.encodePacked(
                    _INVALID_LOAN_PARAMETER_SELECTOR_,
                    _LENDER_ROYALTIES_ERROR_ID_
                )
            );
        }
        // Time expiry revert check
        else if (
            _contractTerms.termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_
        ) {
            return (
                false,
                abi.encodePacked(
                    _INVALID_LOAN_PARAMETER_SELECTOR_,
                    _TIME_EXPIRY_ERROR_ID_
                )
            );
        }
        // Duration revert check
        else if (_contractTerms.duration == 0) {
            return (
                false,
                abi.encodePacked(
                    _INVALID_LOAN_PARAMETER_SELECTOR_,
                    _DURATION_ERROR_ID_
                )
            );
        }
        // Grace period revert check
        else if (_contractTerms.gracePeriod >= _contractTerms.duration) {
            return (
                false,
                abi.encodePacked(
                    _INVALID_LOAN_PARAMETER_SELECTOR_,
                    _GRACE_PERIOD_ERROR_ID_
                )
            );
        }
        // Duration revert check
        else if (
            (_loanStart +
                uint256(_contractTerms.duration) +
                uint256(_contractTerms.gracePeriod)) > type(uint32).max
        ) {
            return (
                false,
                abi.encodePacked(
                    _INVALID_LOAN_PARAMETER_SELECTOR_,
                    _DURATION_ERROR_ID_
                )
            );
        }
        // FIR interval revert check
        else if (_contractTerms.firInterval > 15) {
            return (
                false,
                abi.encodePacked(
                    _INVALID_LOAN_PARAMETER_SELECTOR_,
                    _FIR_INTERVAL_ERROR_ID_
                )
            );
        }
        // FIR interval and fixed interest rate revert check
        else {
            try
                _loanContractHarness.exposed__getTotalFirIntervals(
                    _contractTerms.firInterval,
                    _contractTerms.duration
                )
            returns (uint256 _firInterval) {
                try
                    Interest.compoundWithTopoff(
                        _contractTerms.principal,
                        _contractTerms.fixedInterestRate,
                        _firInterval
                    )
                returns (uint256) {} catch (bytes memory) {
                    // Fixed interest rate revert
                    if (_contractTerms.firInterval != 0)
                        return (
                            false,
                            abi.encodePacked(
                                _INVALID_LOAN_PARAMETER_SELECTOR_,
                                _FIXED_INTEREST_RATE_ERROR_ID_
                            )
                        );
                }
            } catch (bytes memory) {
                // FIR interval rate revert
                return (
                    false,
                    abi.encodePacked(
                        _INVALID_LOAN_PARAMETER_SELECTOR_,
                        _FIR_INTERVAL_ERROR_ID_
                    )
                );
            }
        }

        // All checks passed
        return (true, abi.encodePacked());
    }

    function compareInitLoanCodecError(
        bytes memory _error,
        bytes memory _expectedError
    ) public {
        assertEq(
            bytes8(_error),
            bytes8(_expectedError),
            "0 :: compareInitLoanCodecError :: expected fail type mismatch."
        );
    }

    function getFirIntervalMultiplier(
        uint8 _firInterval
    ) public pure returns (uint256) {
        if (_firInterval == _SECONDLY_) {
            return _SECONDLY_MULTIPLIER_;
        } else if (_firInterval == _MINUTELY_) {
            return _MINUTELY_MULTIPLIER_;
        } else if (_firInterval == _HOURLY_) {
            return _HOURLY_MULTIPLIER_;
        } else if (_firInterval == _DAILY_) {
            return _DAILY_MULTIPLIER_;
        } else if (_firInterval == _WEEKLY_) {
            return _WEEKLY_MULTIPLIER_;
        } else if (_firInterval == _2_WEEKLY_) {
            return _2_WEEKLY_MULTIPLIER_;
        } else if (_firInterval == _4_WEEKLY_) {
            return _4_WEEKLY_MULTIPLIER_;
        } else if (_firInterval == _6_WEEKLY_) {
            return _6_WEEKLY_MULTIPLIER_;
        } else if (_firInterval == _8_WEEKLY_) {
            return _8_WEEKLY_MULTIPLIER_;
        } else if (_firInterval == _360_DAILY_) {
            return _360_DAILY_MULTIPLIER_;
        } else {
            revert StdCodecErrors.InvalidLoanParameter(_FIR_INTERVAL_ERROR_ID_);
        }
    }
}

contract LoanCodecUnitTest is ILoanCodecEvents, LoanCodecInit {
    LoanCodecUtils loanCodecUtils;

    function setUp() public virtual override {
        super.setUp();

        // Deploy LoanCodecUtils
        loanCodecUtils = new LoanCodecUtils();
    }

    /* --------- LoanCodec.totalFirIntervals() --------- */
    /**
     * Fuzz test the total FIR intervals function.
     *
     * @param _debtId The debt ID.
     * @param _seconds The number of seconds to fuzz.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the total FIR intervals getter returns the expected
     * value.
     */
    function testLoanCodec__Fuzz_TotalFirIntervals(
        uint256 _debtId,
        uint256 _seconds,
        ContractTerms memory _contractTerms
    ) public {
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;

        // Pack and store the contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        loanCodecHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Setting the loan agreement updates the duration to account for the grace
        // period. We need to do that here too.
        _contractTerms.duration -= _contractTerms.gracePeriod;

        // Get the total FIR intervals.
        try loanCodecHarness.totalFirIntervals(_debtId, _seconds) returns (
            uint256 _firIntervals
        ) {
            uint256 _firMultiplier = loanCodecUtils.getFirIntervalMultiplier(
                _contractTerms.firInterval
            );

            uint256 _expectedFirIntervals = _seconds <= _contractTerms.duration
                ? _seconds / _firMultiplier
                : _contractTerms.duration / _firMultiplier;

            assertEq(
                _firIntervals,
                _expectedFirIntervals,
                "0 :: unexpected total FIR intervals."
            );
        } catch (bytes memory _err) {
            if (_seconds > type(uint32).max) {
                assertEq(
                    bytes4(_err),
                    _OVERFLOW_CAST_SELECTOR_,
                    "0 :: 'overflow cast selector' failure expected."
                );
            }
        }
    }

    /* --------- LoanCodec._validateLoanTerms() -------- */
    /**
     * Fuzz test the debt term validator function.
     *
     * @param _contractTerms The contract terms.
     * @param _loanStart The loan start time.
     *
     * @dev Full pass if the debt term getters return the expected values.
     */
    function testLoanCodec__Fuzz_ValidateLoanTerms(
        uint64 _loanStart,
        ContractTerms memory _contractTerms
    ) public {
        // Get expected pass/fail status
        (bool _expectedSuccess, bytes memory _expectedData) = loanCodecUtils
            .expectedContractTermsValidity(
                _contractTerms,
                loanCodecHarness,
                _loanStart
            );

        // Pack and store the contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Test the validator function.
        try
            loanCodecHarness.exposed__validateLoanTerms(
                _packedContractTerms,
                _loanStart,
                _contractTerms.principal
            )
        {
            assertTrue(_expectedSuccess, "0 :: expected success is false.");
        } catch (bytes memory _err) {
            assertFalse(_expectedSuccess, "1 :: expected success is true.");
            assertEq(
                bytes8(_err),
                bytes8(_expectedData),
                "2 :: expected fail type mismatch."
            );
            return;
        }
    }

    /* ------- LoanCodec._getTotalFirIntervals() ------- */
    /**
     * Fuzz test the total FIR intervals getter function.
     *
     * @param _firInterval The FIR interval.
     * @param _seconds The number of seconds to fuzz.
     *
     * @dev Full pass if the total FIR intervals getter returns the expected
     * value.
     * @dev Caught fail/pass if the total FIR intervals getter reverts with the
     * expected error when the FIR interval is invalid.
     */
    function testLoanCodec__Fuzz_GetTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) public {
        try
            loanCodecHarness.exposed__getTotalFirIntervals(
                _firInterval,
                _seconds
            )
        returns (uint256 _firIntervals) {
            uint256 _expectedFirMultiplier = loanCodecUtils
                .getFirIntervalMultiplier(uint8(_firInterval));
            assertEq(
                _seconds / _expectedFirMultiplier,
                _firIntervals,
                "0 :: unexpected total FIR intervals."
            );
        } catch (bytes memory _err) {
            if (_firInterval > 8 && _firInterval != 14) {
                assertEq(
                    bytes8(_err),
                    bytes8(
                        abi.encodePacked(
                            _INVALID_LOAN_PARAMETER_SELECTOR_,
                            _FIR_INTERVAL_ERROR_ID_
                        )
                    ),
                    "0 :: 'invalid loan parameter' failure expected."
                );
            }
        }
    }

    /* --------- LoanCodec._setLoanAgreement() --------- */
    /**
     * See {testDebtTerm__Fuzz_Getters} for testing.
     */

    /* ----------- LoanCodec._updateLoanState() ----------- */
    /**
     * Fuzz test the loan state updater function.
     *
     * @param _debtId The debt ID.
     * @param _newLoanState The new loan state.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the loan state is updated as expected and the other
     * original contract terms are unchanged.
     * @dev Caught fail/pass if the loan state updater reverts with the expected
     * error when the new loan state is the same as the original loan state.
     *
     * See {LoanContractFIRIntervals} for more information on the valid loan
     * states.
     */
    function testLoanCodec__Fuzz_UpdateLoanState(
        uint256 _debtId,
        uint8 _newLoanState,
        ContractTerms memory _contractTerms
    ) public {
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint8 _oldLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        // Pack and store the contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        loanCodecHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Setting the loan agreement updates the duration to account for the grace
        // period. We need to do that here too.
        _contractTerms.duration -= _contractTerms.gracePeriod;

        // Check the unpacked contract terms.
        debtTermsUtils.checkLoanTerms(
            address(loanCodecHarness),
            _debtId,
            _activeLoanIndex,
            _now,
            _contractTerms
        );

        // Set the loan state.
        if (_oldLoanState != _newLoanState && _newLoanState <= 0x0f) {
            vm.expectEmit(true, true, true, true, address(loanCodecHarness));
            emit LoanStateChanged(_debtId, _newLoanState, _oldLoanState);
        }
        try loanCodecHarness.exposed__updateLoanState(_debtId, _newLoanState) {
            // Check the updated unpacked contract terms.
            debtTermsUtils.checkLoanTerms(
                address(loanCodecHarness),
                _debtId,
                _activeLoanIndex,
                _now,
                _newLoanState,
                _contractTerms
            );
        } catch (bytes memory _err) {
            // Check if the updated loan state is illegal due to the current loan
            // state and the new loan state being the same.
            if (
                _newLoanState == loanCodecHarness.loanState(_debtId) ||
                _newLoanState > 0x0f
            ) {
                assertEq(
                    bytes4(_err),
                    _ILLEGAL_TERMS_UPDATE_SELECTOR_,
                    "0 :: 'illegal terms update' failure expected."
                );
            }
        }
    }

    /* ----------- LoanCodec._updateLoanTimes() ----------- */
    /**
     * Fuzz test the loan times updater function.
     *
     * @param _debtId The debt ID.
     * @param _warpTime The new loan time.
     * @param _contractTerms The contract terms.
     * states.
     *
     * @dev Full pass if the loan times are updated as expected and the other
     * original contract terms are unchanged.
     */
    function testLoanCodec__Fuzz_UpdateLoanTimes(
        uint256 _debtId,
        uint32 _warpTime,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(_warpTime > 0);
        cleanContractTerms(_contractTerms);

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;
        uint8 _expectedLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        // Pack and store the contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        loanCodecHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Setting the loan agreement updates the duration to account for the grace
        // period. We need to do that here too.
        _contractTerms.duration -= _contractTerms.gracePeriod;

        // Check the unpacked contract terms.
        debtTermsUtils.checkLoanTerms(
            address(loanCodecHarness),
            _debtId,
            _activeLoanIndex,
            _now,
            _expectedLoanState,
            _contractTerms
        );

        // Store original debt terms.
        uint256 _loanStart = loanCodecHarness.loanStart(_debtId);
        uint256 _loanClose = loanCodecHarness.loanClose(_debtId);
        uint256 _loanDuration = loanCodecHarness.loanDuration(_debtId);

        // Warp time.
        _now += uint64(_warpTime);
        vm.warp(uint256(_now));

        // Update the loan times.
        loanCodecHarness.exposed__updateLoanTimes(_debtId, 0);

        // Loan close should remain unchanged.
        assertEq(
            _loanClose,
            loanCodecHarness.loanClose(_debtId),
            "0 :: 'loanClose' mismatch."
        );

        uint256 _expectedLoanStart;

        if (_now > _loanStart) {
            // Update expected terms.
            _expectedLoanStart = _now > _loanClose ? _loanClose : _now;

            // If the current time is greater than the loan start, the grace period
            // is past and should be 0.
            _contractTerms.gracePeriod = 0;

            // If the current time is greater than the loan close, the loan duration
            // should be the loan close time minus the updated loan start time.
            _contractTerms.duration = uint32(_loanClose - _expectedLoanStart);

            // Loan start should be updated.
            assertEq(
                loanCodecHarness.loanStart(_debtId),
                _expectedLoanStart,
                "1 :: 'loanStart' mismatch."
            );

            // Loan duration should be updated.
            assertEq(
                loanCodecHarness.loanDuration(_debtId),
                _loanClose - _expectedLoanStart,
                "2 :: 'loanDuration' mismatch."
            );
        } else {
            // Update expected terms.
            _expectedLoanStart = _loanStart;
            _contractTerms.gracePeriod -= _warpTime;

            // The loan start time should remain unchanged.
            assertEq(
                loanCodecHarness.loanStart(_debtId),
                _loanStart,
                "3 :: 'loanStart' mismatch."
            );

            // The loan start time should remain unchanged and the sum of the
            // updated current time and grace period should be equal to the loan
            // original start time.
            assertEq(
                loanCodecHarness.loanStart(_debtId),
                _now + _contractTerms.gracePeriod,
                "4 :: 'loanStart' mismatch."
            );

            // The loan duration should remain unchanged.
            assertEq(
                _loanDuration,
                loanCodecHarness.loanDuration(_debtId),
                "5 :: 'loanDuration' mismatch."
            );
        }

        // The loan close time  and its relations to loan start and duration
        // should remain unchanged.
        assertEq(
            loanCodecHarness.loanStart(_debtId) +
                loanCodecHarness.loanDuration(_debtId),
            _loanClose,
            "6 :: 'loanClose' mismatch."
        );

        assertEq(
            _expectedLoanStart + loanCodecHarness.loanDuration(_debtId),
            _loanClose,
            "7 :: 'loanClose' mismatch."
        );

        assertEq(
            loanCodecHarness.loanClose(_debtId),
            _loanClose,
            "8 :: 'loanClose' mismatch."
        );

        assertEq(
            _expectedLoanStart + _contractTerms.duration,
            loanCodecHarness.loanClose(_debtId),
            "9 :: 'loanClose' mismatch."
        );

        // Check the updated unpacked contract terms.
        debtTermsUtils.checkLoanTerms(
            address(loanCodecHarness),
            _debtId,
            _activeLoanIndex,
            _now > _loanStart ? _expectedLoanStart : _now,
            _expectedLoanState,
            _contractTerms
        );
    }
}
