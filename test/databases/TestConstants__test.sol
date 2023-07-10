// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *                  LOAN TERMS                      *
 * ------------------------------------------------ */
uint8 constant _FIR_INTERVAL_ = 14;
uint8 constant _FIXED_INTEREST_RATE_ = 10; // 0.10
uint8 constant _IS_FIXED_ = 0; // false
uint8 constant _COMMITAL_ = 25; // 0.25
uint256 constant _PRINCIPAL_ = 10000000000; // WEI
uint32 constant _GRACE_PERIOD_ = 86400;
uint32 constant _DURATION_ = 1209600;
uint32 constant _TERMS_EXPIRY_ = 86400;
uint8 constant _LENDER_ROYALTIES_ = 10;

uint8 constant _ALT_FIR_INTERVAL_ = 14;
uint8 constant _ALT_FIXED_INTEREST_RATE_ = 5; // 0.05
uint256 constant _ALT_PRINCIPAL_ = 4; // ETH // 226854911280625642308916404954512140970
uint32 constant _ALT_GRACE_PERIOD_ = 60 * 60 * 24 * 5; // 604800 (5 days)
uint32 constant _ALT_DURATION_ = 60 * 60 * 24 * 360 * 1; // 62208000 (1 year)
uint32 constant _ALT_TERMS_EXPIRY_ = 60 * 60 * 24 * 4; // 1209600 (4 days)
uint8 constant _ALT_LENDER_ROYALTIES_ = 10; // 0.10
