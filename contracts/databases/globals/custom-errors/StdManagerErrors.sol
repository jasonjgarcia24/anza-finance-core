// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *      Loan Manager Custom Error Selectors         *
 * ------------------------------------------------ */
bytes4 constant _INVALID_PARTICIPANT_SELECTOR_ = 0xa145c43e; // bytes4(keccak256("InvalidParticipant()"))
bytes4 constant _ILLEGAL_TERMS_UPDATE_SELECTOR_ = 0x75d55ed4; // bytes4(keccak256("IllegalTermsUpdate()"))
bytes4 constant _INVALID_COMMITTED_DEBT_SELECTOR_ = 0x88946271; // bytes4(keccak256("InvalidCommittedDebt()"))

library StdManagerErrors {
    /* ------------------------------------------------ *
     *           Loan Manager Custom Errors             *
     * ------------------------------------------------ */
    error InvalidParticipant();
    error IllegalTermsUpdate();
    error InvalidCommittedDebt();
}
