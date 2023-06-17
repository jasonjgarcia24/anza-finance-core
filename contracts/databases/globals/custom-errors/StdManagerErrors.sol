// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *      Loan Manager Custom Error Selectors         *
 * ------------------------------------------------ */
bytes4 constant _INVALID_PARTICIPANT_SELECTOR_ = 0xa145c43e; // bytes4(keccak256("InvalidParticipant()"))

library StdManagerErrors {
    /* ------------------------------------------------ *
     *           Loan Manager Custom Errors             *
     * ------------------------------------------------ */
    error InvalidParticipant();
}
