// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *                 Contract Numbers                 *
 * ------------------------------------------------ */
uint256 constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;
uint256 constant _MAX_REFINANCES_ = 2008;
uint256 constant _MAX_DEBT_PRINCIPAL_ = type(uint256).max / _MAX_REFINANCES_;
uint256 constant _MAX_DEBT_ID_ = 57896044618658097711785492504343953926634992332820282019728792003956564819967; // (type(uint256).max / 2) - 1;
