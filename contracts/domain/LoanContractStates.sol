// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* ------------------------------------------------ *
 *                  Loan States                     *
 * ------------------------------------------------ */
uint8 constant _UNDEFINED_STATE_ = 0;
uint8 constant _NONLEVERAGED_STATE_ = 1;
uint8 constant _UNSPONSORED_STATE_ = 2;
uint8 constant _SPONSORED_STATE_ = 3;
uint8 constant _FUNDED_STATE_ = 4;
uint8 constant _ACTIVE_GRACE_STATE_ = 5;
uint8 constant _ACTIVE_STATE_ = 6;
uint8 constant _DEFAULT_STATE_ = 7;
uint8 constant _COLLECTION_STATE_ = 8;
uint8 constant _AUCTION_STATE_ = 9;
uint8 constant _AWARDED_STATE_ = 10;
uint8 constant _PAID_PENDING_STATE_ = 11;
uint8 constant _CLOSE_STATE_ = 12;
uint8 constant _PAID_STATE_ = 13;
uint8 constant _CLOSE_DEFAULT_STATE_ = 14;
