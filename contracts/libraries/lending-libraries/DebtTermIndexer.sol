// SPDX-Liscense-Identifier: MIT
pragma solidity 0.8.20;

import "@lending-constants/LoanContractTermMaps.sol";
import {_ILLEGAL_TERMS_UPDATE_SELECTOR_} from "@custom-errors/StdManagerErrors.sol";

import "@abdk-libraries/ABDKMath64x64.sol";

/**
 * @title DebtTermIndexer
 * @author jjgarcia.eth
 * @notice The DebtTermIndexer library provides functions to index and set
 * the debt terms for a given debt ID.
 *
 * @dev The debt terms are packed into a single bytes32 value. The debt terms
 * are indexed as follows within the DebtTermMap.packedDebtTerms mapping:
 *  > 004 - [0..3]     `loanState`
 *  > 004 - [4..7]     `firInterval`
 *  > 008 - [8..15]    `fixedInterestRate`
 *  > 064 - [16..79]   `loanStart`
 *  > 032 - [80..111]  `loanDuration`
 *  > 004 - [112..115] `isFixed`
 *  > 008 - [116..123] `commital`
 *  > 160 - [124..239]  unused space
 *  > 008 - [240..247] `lenderRoyalties`
 *  > 008 - [248..255] `activeLoanIndex`
 *
 * Alternatively, see {LendingContractTermMaps} for mappings.
 */
library DebtTermIndexer {
    /**
     * The packed debt term mapping for each debt ID.
     *
     * @param packedDebtTerms The packed debt terms for each debt ID.
     */
    struct DebtTermMap {
        mapping(uint256 debtId => bytes32) packedDebtTerms;
    }

    /**
     * Modifier to ensure that the debt terms map has not been initialized
     * and can therefore be set.
     *
     * @param _packedDebtTerms The initialized debt terms.
     */
    modifier onlyUnlocked(bytes32 _packedDebtTerms) {
        __verifyUnlocked(_packedDebtTerms);
        _;
    }

    /**
     * Returns the packed debt terms for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * @return The packed debt terms.
     */
    function _debtTerms(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (bytes32) {
        return _map.packedDebtTerms[_debtId];
    }

    /**
     * Sets the packed debt terms for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     * @param _packedDebtTerms The debt terms to set.
     */
    function _setDebtTerms(
        DebtTermMap storage _map,
        uint256 _debtId,
        bytes32 _packedDebtTerms
    ) internal onlyUnlocked(_map.packedDebtTerms[_debtId]) {
        _map.packedDebtTerms[_debtId] = _packedDebtTerms;
    }

    /**
     * Updates the packed debt terms for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     * @param _packedDebtTerms The debt terms to update to.
     */
    function _updateDebtTerms(
        DebtTermMap storage _map,
        uint256 _debtId,
        bytes32 _packedDebtTerms
    ) internal {
        _map.packedDebtTerms[_debtId] = _packedDebtTerms;
    }

    /**
     * Returns the loan state for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for the
     * `_LOAN_STATE_MAP_`.
     *
     * @return _uLoanState The unpacked loan state.
     */
    function _loanState(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanState) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }
    }

    /**
     * Returns the fixed interest rate (FIR) interval for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_FIR_INTERVAL_POS_`
     * and `_FIR_INTERVAL_MAP_`.
     *
     * @return _uFirInterval The unpacked FIR interval.
     */
    function _firInterval(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uFirInterval) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uFirInterval := shr(
                _FIR_INTERVAL_POS_,
                and(_contractTerms, _FIR_INTERVAL_MAP_)
            )
        }
    }

    /**
     * Returns the fixed interest rate (FIR) for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_FIR_POS_` and
     * `_FIR_MAP_`.
     *
     * @return _uFixedInterestRate The unpacked fixed interest rate.
     */
    function _fixedInterestRate(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uFixedInterestRate) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uFixedInterestRate := shr(
                _FIR_POS_,
                and(_contractTerms, _FIR_MAP_)
            )
        }
    }

    /**
     * Returns the is fixed status for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_IS_FIXED_POS_` and
     * `_IS_FIXED_MAP_`.
     *
     * @return _uIsFixed The unpacked is fixed status.
     */
    function _isFixed(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uIsFixed) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uIsFixed := shr(
                _IS_FIXED_POS_,
                and(_contractTerms, _IS_FIXED_MAP_)
            )
        }
    }

    /**
     * Returns the loan last checked timestamp for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * @return the loan last checked timestamp.
     */
    function _loanLastChecked(
        DebtTermMap storage _map,
        uint256 _debtId
    ) external view returns (uint256) {
        return _loanStart(_map, _debtId);
    }

    /**
     * Returns the loan start timestamp for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_START_POS_` and
     * `_LOAN_START_MAP_`.
     *
     * @return _uLoanStart The unpacked loan start timestamp.
     */
    function _loanStart(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanStart) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )
        }
    }

    /**
     * Returns the loan duration for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_DURATION_POS_`
     * and `_LOAN_DURATION_MAP_`.
     *
     * @return _uLoanDuration The unpacked loan duration.
     */
    function _loanDuration(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanDuration) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanDuration := shr(
                _LOAN_DURATION_POS_,
                and(_contractTerms, _LOAN_DURATION_MAP_)
            )
        }
    }

    /**
     * Returns the loan commital duration for a given debt ID.
     *
     * @dev The loan commital is the duration commitment of the borrower to
     * the lender.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_COMMITAL_POS_` and
     * `_LOAN_COMMITAL_MAP_`.
     *
     * @return _uLoanCommital The unpacked loan commital duration.
     */
    function _loanCommital(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanCommital) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanCommital := add(
                shr(_LOAN_START_POS_, and(_contractTerms, _LOAN_START_MAP_)),
                shr(
                    _LOAN_COMMITAL_POS_,
                    and(_contractTerms, _LOAN_COMMITAL_MAP_)
                )
            )
        }
    }

    /**
     * Returns the loan close timestamp for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_START_POS_`,
     * `_LOAN_START_MAP_`, `_LOAN_DURATION_POS_`, and `_LOAN_DURATION_MAP_`.
     *
     * @return _uLoanClose The unpacked loan close timestamp.
     */
    function _loanClose(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanClose) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanClose := add(
                shr(_LOAN_START_POS_, and(_contractTerms, _LOAN_START_MAP_)),
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )
        }
    }

    /**
     * Returns the lender royalties on a refinance transaction to another
     * lender.
     *
     * @dev If the lender royalties is 0, the lender will not receive any
     * royalties on a refinance transaction. The lender royalties is a
     * percentage of the interest paid by the borrower to the lender.
     * Therefore, it must be within the range of 0 - 100.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for
     * `_LENDER_ROYALTIES_POS_` and `_LENDER_ROYALTIES_MAP_`.
     *
     * @return _uLenderRoyalties The unpacked lender royalties.
     */
    function _lenderRoyalties(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLenderRoyalties) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLenderRoyalties := shr(
                _LENDER_ROYALTIES_POS_,
                and(_contractTerms, _LENDER_ROYALTIES_MAP_)
            )
        }
    }

    /**
     * Returns the active loan count of a given collateralized token.
     *
     * TODO: This is not used anywhere. It is also captured in the DebtMaps
     * database. Remove?
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_COUNT_POS_` and
     * `_LOAN_COUNT_MAP_`.
     *
     * @return _uActiveLoanCount The unpacked active loan count.
     */
    function _activeLoanCount(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uActiveLoanCount) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uActiveLoanCount := shr(
                _LOAN_COUNT_POS_,
                and(_contractTerms, _LOAN_COUNT_MAP_)
            )
        }
    }

    /**
     * Returns the committed status of the current debt.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * @return True if the debt is committed, false if not.
     */
    function _checkCommitted(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (bool) {
        return _loanCommital(_map, _debtId) <= block.timestamp;
    }

    /**
     * Reverts with a illegal terms update error if the debt ID terms are
     * already in use.
     *
     * @param _packedDebtTerms The packed debt terms.
     */
    function __verifyUnlocked(bytes32 _packedDebtTerms) private pure {
        assembly {
            if gt(_packedDebtTerms, 0) {
                mstore(0x20, _ILLEGAL_TERMS_UPDATE_SELECTOR_)
                revert(0x20, 0x04)
            }
        }
    }
}
