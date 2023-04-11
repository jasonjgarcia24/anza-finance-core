// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LibLoanContractConstants {
    uint256 public constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;
    uint256 public constant _UINT32_MAX_ = 4294967295;
}

library LibLoanContractStates {
    uint8 public constant _UNDEFINED_STATE_ = 0;
    uint8 public constant _NONLEVERAGED_STATE_ = 1;
    uint8 public constant _UNSPONSORED_STATE_ = 2;
    uint8 public constant _SPONSORED_STATE_ = 3;
    uint8 public constant _FUNDED_STATE_ = 4;
    uint8 public constant _ACTIVE_GRACE_STATE_ = 5;
    uint8 public constant _ACTIVE_STATE_ = 6;
    uint8 public constant _DEFAULT_STATE_ = 7;
    uint8 public constant _COLLECTION_STATE_ = 8;
    uint8 public constant _AUCTION_STATE_ = 9;
    uint8 public constant _AWARDED_STATE_ = 10;
    uint8 public constant _PAID_PENDING_STATE_ = 11;
    uint8 public constant _CLOSE_STATE_ = 12;
    uint8 public constant _PAID_STATE_ = 13;
    uint8 public constant _CLOSE_DEFAULT_STATE_ = 14;
}

library LibLoanContractFIRIntervals {
    uint8 public constant _SECONDLY_ = 0;
    uint8 public constant _MINUTELY_ = 1;
    uint8 public constant _HOURLY_ = 2;
    uint8 public constant _DAILY_ = 3;
    uint8 public constant _WEEKLY_ = 4;
    uint8 public constant _2_WEEKLY_ = 5;
    uint8 public constant _4_WEEKLY_ = 6;
    uint8 public constant _6_WEEKLY_ = 7;
    uint8 public constant _8_WEEKLY_ = 8;
    uint8 public constant _MONTHLY_ = 9;
    uint8 public constant _2_MONTHLY_ = 10;
    uint8 public constant _3_MONTHLY_ = 11;
    uint8 public constant _4_MONTHLY_ = 12;
    uint8 public constant _6_MONTHLY_ = 13;
    uint8 public constant _360_DAILY_ = 14;
    uint8 public constant _ANNUALLY_ = 15;
}

library LibLoanContractFIRIntervalMultipliers {
    uint256 public constant _SECONDLY_MULTIPLIER_ = 1;
    uint256 public constant _MINUTELY_MULTIPLIER_ = 60;
    uint256 public constant _HOURLY_MULTIPLIER_ = 60 * 60;
    uint256 public constant _DAILY_MULTIPLIER_ = 60 * 60 * 24;
    uint256 public constant _WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7;
    uint256 public constant _2_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 2;
    uint256 public constant _4_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 4;
    uint256 public constant _6_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 6;
    uint256 public constant _8_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 8;
    uint256 public constant _360_DAILY_MULTIPLIER_ = 60 * 60 * 24 * 360;
}

library LibLoanContractPackMappings {
    uint256 public constant _LOAN_STATE_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0;
    uint256 public constant _LOAN_STATE_MAP_ =
        0x000000000000000000000000000000000000000000000000000000000000000F;
    uint256 public constant _FIR_INTERVAL_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0F;
    uint256 public constant _FIR_INTERVAL_MAP_ =
        0x00000000000000000000000000000000000000000000000000000000000000F0;
    uint256 public constant _FIR_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FF;
    uint256 public constant _FIR_MAP_ =
        0x000000000000000000000000000000000000000000000000000000000000FF00;
    uint256 public constant _LOAN_START_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFF;
    uint256 public constant _LOAN_START_MAP_ =
        0x0000000000000000000000000000000000000000000000000000FFFFFFFF0000;
    uint256 public constant _LOAN_DURATION_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFF;
    uint256 public constant _LOAN_DURATION_MAP_ =
        0x00000000000000000000000000000000000000000000FFFFFFFF000000000000;
    uint256 public constant _IS_DIRECT_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFF;
    uint256 public constant _IS_DIRECT_MAP_ =
        0x0000000000000000000000000000000000000000000F00000000000000000000;
    uint256 public constant _COMMITAL_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant _COMMITAL_MAP_ =
        0x00000000000000000000000000000000000000000FF000000000000000000000;
    uint256 public constant _LENDER_ROYALTIES_MASK_ =
        0xFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant _LENDER_ROYALTIES_MAP_ =
        0x00FF000000000000000000000000000000000000000000000000000000000000;
    uint256 public constant _LOAN_COUNT_MASK_ =
        0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant _LOAN_COUNT_MAP_ =
        0xFF00000000000000000000000000000000000000000000000000000000000000;

    uint8 public constant _LOAN_STATE_POS_ = 0;
    uint8 public constant _FIR_INTERVAL_POS_ = 4;
    uint8 public constant _FIR_POS_ = 8;
    uint8 public constant _LOAN_START_POS_ = 16;
    uint8 public constant _LOAN_DURATION_POS_ = 48;
    uint8 public constant _BORROWER_POS_ = 80;
    uint8 public constant _LENDER_ROYALTIES_POS_ = 240;
    uint8 public constant _LOAN_COUNT_POS_ = 248;
}

library LibLoanContractStandardErrors {
    bytes4 public constant _LOAN_STATE_ERROR_ID_ = 0xdacce9d3;
    bytes4 public constant _FIR_INTERVAL_ERROR_ID_ = 0xa13e8948;
    bytes4 public constant _DURATION_ERROR_ID_ = 0xfcbf8511;
    bytes4 public constant _PRINCIPAL_ERROR_ID_ = 0x6a901435;
    bytes4 public constant _FIXED_INTEREST_RATE_ERROR_ID_ = 0x8fe03ac3;
    bytes4 public constant _GRACE_PERIOD_ERROR_ID_ = 0xb677e65e;
    bytes4 public constant _TIME_EXPIRY_ERROR_ID_ = 0x67b21a5c;
    bytes4 public constant _LENDER_ROYALTIES_ERROR_ID_ = 0xecc752dd;
}
