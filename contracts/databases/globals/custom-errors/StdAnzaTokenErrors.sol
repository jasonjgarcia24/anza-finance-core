// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *         Anza Token Custom Error Messages         *
 * ------------------------------------------------ */
error IllegalMint();
error IllegalTransfer();

/* ------------------------------------------------ *
 *         Anza Token Custom Error Selectors        *
 * ------------------------------------------------ */
bytes4 constant _INVALID_TOKEN_ID_SELECTOR_ = 0x3f6cc768; // bytes4(keccak256("InvalidTokenId()"))
