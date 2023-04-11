// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* ------------------------------------------------ *
 *       Fixed Interest Rate (FIR) Intervals        *
 * ------------------------------------------------ */
//  Need to validate duration > FIR interval
uint8 constant _SECONDLY_ = 0;
uint8 constant _MINUTELY_ = 1;
uint8 constant _HOURLY_ = 2;
uint8 constant _DAILY_ = 3;
uint8 constant _WEEKLY_ = 4;
uint8 constant _2_WEEKLY_ = 5;
uint8 constant _4_WEEKLY_ = 6;
uint8 constant _6_WEEKLY_ = 7;
uint8 constant _8_WEEKLY_ = 8;
uint8 constant _MONTHLY_ = 9;
uint8 constant _2_MONTHLY_ = 10;
uint8 constant _3_MONTHLY_ = 11;
uint8 constant _4_MONTHLY_ = 12;
uint8 constant _6_MONTHLY_ = 13;
uint8 constant _360_DAILY_ = 14;
uint8 constant _ANNUALLY_ = 15;

/* ------------------------------------------------ *
 *               FIR Interval Multipliers           *
 * ------------------------------------------------ */
uint256 constant _SECONDLY_MULTIPLIER_ = 1;
uint256 constant _MINUTELY_MULTIPLIER_ = 60;
uint256 constant _HOURLY_MULTIPLIER_ = 60 * 60;
uint256 constant _DAILY_MULTIPLIER_ = 60 * 60 * 24;
uint256 constant _WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7;
uint256 constant _2_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 2;
uint256 constant _4_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 4;
uint256 constant _6_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 6;
uint256 constant _8_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 8;
uint256 constant _360_DAILY_MULTIPLIER_ = 60 * 60 * 24 * 360;
