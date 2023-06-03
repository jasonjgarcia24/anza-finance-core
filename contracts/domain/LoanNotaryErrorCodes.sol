// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *        Loan Notary Custom Error Selectors          *
 * ------------------------------------------------ */
bytes4 constant _INVALID_PARTICIPANT_SELECTOR_ = 0xa145c43e; // bytes4(keccak256("InvalidParticipant()"))
bytes4 constant _INVALID_SIGNATURE_LENGTH_SELECTOR_ = 0x4be6321b; // bytes4(keccak256("InvalidSignatureLength()"))
