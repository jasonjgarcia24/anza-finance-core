// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *             Loan Agreement Errors                *
 * ------------------------------------------------ */
error InvalidCollateral();
error InvalidLoanState();

/* ------------------------------------------------ *
 *           Loan Term Error Selectors              *
 * ------------------------------------------------ */
// Example: bytes4(keccak256("_LOAN_STATE_ERROR_ID_"))
bytes4 constant _LOAN_STATE_ERROR_ID_ = 0xd06c1bad;
bytes4 constant _FIR_INTERVAL_ERROR_ID_ = 0xfcacf94a;
bytes4 constant _DURATION_ERROR_ID_ = 0x7cde7ce7;
bytes4 constant _PRINCIPAL_ERROR_ID_ = 0xbbc5f09e;
bytes4 constant _FIXED_INTEREST_RATE_ERROR_ID_ = 0xbfe4482e;
bytes4 constant _GRACE_PERIOD_ERROR_ID_ = 0x3bc4ef6a;
bytes4 constant _TIME_EXPIRY_ERROR_ID_ = 0xf0c15f40;
bytes4 constant _LENDER_ROYALTIES_ERROR_ID_ = 0xe1f90bbd;
