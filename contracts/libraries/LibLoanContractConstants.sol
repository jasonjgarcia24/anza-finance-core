// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../domain/LoanContractErrorCodes.sol";
import "../domain/LoanContractFIRIntervals.sol";
import "../domain/LoanContractNumbers.sol";
import "../domain/LoanContractTermMaps.sol";
import "../domain/LoanContractRoles.sol";
import "../domain/LoanContractStates.sol";

library LibLoanContractStandardErrors {
    bytes4 public constant LOAN_STATE_ERROR_ID = _LOAN_STATE_ERROR_ID_;
    bytes4 public constant FIR_INTERVAL_ERROR_ID = _FIR_INTERVAL_ERROR_ID_;
    bytes4 public constant DURATION_ERROR_ID = _DURATION_ERROR_ID_;
    bytes4 public constant PRINCIPAL_ERROR_ID = _PRINCIPAL_ERROR_ID_;
    bytes4 public constant FIXED_INTEREST_RATE_ERROR_ID =
        _FIXED_INTEREST_RATE_ERROR_ID_;
    bytes4 public constant GRACE_PERIOD_ERROR_ID = _GRACE_PERIOD_ERROR_ID_;
    bytes4 public constant TIME_EXPIRY_ERROR_ID = _TIME_EXPIRY_ERROR_ID_;
    bytes4 public constant LENDER_ROYALTIES_ERROR_ID =
        _LENDER_ROYALTIES_ERROR_ID_;
}

library LibLoanContractFIRIntervals {
    uint8 public constant SECONDLY = _SECONDLY_;
    uint8 public constant MINUTELY = _MINUTELY_;
    uint8 public constant HOURLY = _HOURLY_;
    uint8 public constant DAILY = _DAILY_;
    uint8 public constant WEEKLY = _WEEKLY_;
    uint8 public constant _2_WEEKLY = _2_WEEKLY_;
    uint8 public constant _4_WEEKLY = _4_WEEKLY_;
    uint8 public constant _6_WEEKLY = _6_WEEKLY_;
    uint8 public constant _8_WEEKLY = _8_WEEKLY_;
    uint8 public constant MONTHLY = _MONTHLY_;
    uint8 public constant _2_MONTHLY = _2_MONTHLY_;
    uint8 public constant _3_MONTHLY = _3_MONTHLY_;
    uint8 public constant _4_MONTHLY = _4_MONTHLY_;
    uint8 public constant _6_MONTHLY = _6_MONTHLY_;
    uint8 public constant _360_DAILY = _360_DAILY_;
    uint8 public constant ANNUALLY = _ANNUALLY_;
}

library LibLoanContractFIRIntervalMultipliers {
    uint256 public constant SECONDLY_MULTIPLIER = _SECONDLY_MULTIPLIER_;
    uint256 public constant MINUTELY_MULTIPLIER = _MINUTELY_MULTIPLIER_;
    uint256 public constant HOURLY_MULTIPLIER = _HOURLY_MULTIPLIER_;
    uint256 public constant DAILY_MULTIPLIER = _DAILY_MULTIPLIER_;
    uint256 public constant WEEKLY_MULTIPLIER = _WEEKLY_MULTIPLIER_;
    uint256 public constant _2_WEEKLY_MULTIPLIER = _2_WEEKLY_MULTIPLIER_;
    uint256 public constant _4_WEEKLY_MULTIPLIER = _4_WEEKLY_MULTIPLIER_;
    uint256 public constant _6_WEEKLY_MULTIPLIER = _6_WEEKLY_MULTIPLIER_;
    uint256 public constant _8_WEEKLY_MULTIPLIER = _8_WEEKLY_MULTIPLIER_;
    uint256 public constant _360_DAILY_MULTIPLIER = _360_DAILY_MULTIPLIER_;
}

library LibLoanContractNumbers {
    uint256 public constant SECONDS_PER_24_MINUTES_RATIO_SCALED =
        _SECONDS_PER_24_MINUTES_RATIO_SCALED_;
    uint256 public constant UINT32_MAX = _UINT32_MAX_;
}

library LibLoanContractTermMaps {
    uint256 public constant LOAN_STATE_MASK = _LOAN_STATE_MASK_;
    uint256 public constant LOAN_STATE_MAP = _LOAN_STATE_MAP_;
    uint256 public constant FIR_INTERVAL_MASK = _FIR_INTERVAL_MASK_;
    uint256 public constant FIR_INTERVAL_MAP = _FIR_INTERVAL_MAP_;
    uint256 public constant FIR_MASK = _FIR_MASK_;
    uint256 public constant FIR_MAP = _FIR_MAP_;
    uint256 public constant LOAN_START_MASK = _LOAN_START_MASK_;
    uint256 public constant LOAN_START_MAP = _LOAN_START_MAP_;
    uint256 public constant LOAN_DURATION_MASK = _LOAN_DURATION_MASK_;
    uint256 public constant LOAN_DURATION_MAP = _LOAN_DURATION_MAP_;
    uint256 public constant IS_FIXED_MASK = _IS_FIXED_MASK_;
    uint256 public constant IS_FIXED_MAP = _IS_FIXED_MAP_;
    uint256 public constant COMMITAL_MASK = _COMMITAL_MASK_;
    uint256 public constant COMMITAL_MAP = _COMMITAL_MAP_;
    uint256 public constant LENDER_ROYALTIES_MASK = _LENDER_ROYALTIES_MASK_;
    uint256 public constant LENDER_ROYALTIES_MAP = _LENDER_ROYALTIES_MAP_;
    uint256 public constant LOAN_COUNT_MASK = _LOAN_COUNT_MASK_;
    uint256 public constant LOAN_COUNT_MAP = _LOAN_COUNT_MAP_;

    uint8 public constant LOAN_STATE_POS = _LOAN_STATE_POS_;
    uint8 public constant FIR_INTERVAL_POS = _FIR_INTERVAL_POS_;
    uint8 public constant FIR_POS = _FIR_POS_;
    uint8 public constant LOAN_START_POS = _LOAN_START_POS_;
    uint8 public constant LOAN_DURATION_POS = _LOAN_DURATION_POS_;
    uint8 public constant LENDER_ROYALTIES_POS = _LENDER_ROYALTIES_POS_;
    uint8 public constant LOAN_COUNT_POS = _LOAN_COUNT_POS_;
}

library LibLoanContractRoles {
    bytes32 public constant ADMIN = _ADMIN_;
    bytes32 public constant LOAN_CONTRACT = _LOAN_CONTRACT_;
    bytes32 public constant TREASURER = _TREASURER_;
    bytes32 public constant COLLECTOR = _COLLECTOR_;
    bytes32 public constant DEBT_STOREFRONT = _DEBT_STOREFRONT_;
}

library LibLoanContractStates {
    uint8 public constant UNDEFINED_STATE = _UNDEFINED_STATE_;
    uint8 public constant NONLEVERAGED_STATE = _NONLEVERAGED_STATE_;
    uint8 public constant UNSPONSORED_STATE = _UNSPONSORED_STATE_;
    uint8 public constant SPONSORED_STATE = _SPONSORED_STATE_;
    uint8 public constant FUNDED_STATE = _FUNDED_STATE_;
    uint8 public constant ACTIVE_GRACE_STATE = _ACTIVE_GRACE_STATE_;
    uint8 public constant ACTIVE_STATE = _ACTIVE_STATE_;
    uint8 public constant DEFAULT_STATE = _DEFAULT_STATE_;
    uint8 public constant COLLECTION_STATE = _COLLECTION_STATE_;
    uint8 public constant AUCTION_STATE = _AUCTION_STATE_;
    uint8 public constant AWARDED_STATE = _AWARDED_STATE_;
    uint8 public constant PAID_PENDING_STATE = _PAID_PENDING_STATE_;
    uint8 public constant CLOSE_STATE = _CLOSE_STATE_;
    uint8 public constant PAID_STATE = _PAID_STATE_;
    uint8 public constant CLOSE_DEFAULT_STATE = _CLOSE_DEFAULT_STATE_;
}
