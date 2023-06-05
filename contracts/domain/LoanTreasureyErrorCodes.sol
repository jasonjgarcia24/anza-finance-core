// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *        Loan Treasurey Custom Error Selectors          *
 * ------------------------------------------------ */
bytes4 constant _INVALID_PARTICIPANT_SELECTOR_ = 0xa145c43e; // bytes4(keccak256("InvalidParticipant()"))
bytes4 constant _INVALID_FUNDS_TRANSFER_SELECTOR_ = 0x0ba7499a; // bytes4(keccak256("InvalidFundsTransfer()"))
bytes4 constant _INVACTIVE_LOAN_STATE_SELECTOR_ = 0x90f54c85; // bytes4(keccak256("InactiveLoanState()"))
bytes4 constant _INVALID_LOAN_STATE_SELECTOR_ = 0x8d896c60; // bytes4(keccak256("InvalidLoanState()"))
bytes4 constant _FAILED_PURCHASE_SELECTOR_ = 0xb6468e52; // bytes4(keccak256("FailedPurchase()"))
