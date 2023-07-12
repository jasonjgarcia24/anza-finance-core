// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *                  Loan States                     *
 * ------------------------------------------------ */
uint8 constant _UNDEFINED_STATE_ = 0;

// Active States
uint8 constant _ACTIVE_GRACE_STATE_ = 1;
uint8 constant _ACTIVE_STATE_ = 2;

// Inactive States
uint8 constant _DEFAULT_STATE_ = 3;
uint8 constant _COLLECTION_STATE_ = 4;
uint8 constant _AUCTION_STATE_ = 5;
uint8 constant _AWARDED_STATE_ = 6;

// Closed States
uint8 constant _PAID_PENDING_STATE_ = 7;
uint8 constant _CLOSE_STATE_ = 8;
uint8 constant _PAID_STATE_ = 9;
uint8 constant _CLOSE_DEFAULT_STATE_ = 10;
