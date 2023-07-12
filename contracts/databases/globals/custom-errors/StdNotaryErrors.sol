// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *         Manager Custom Error Selectors           *
 * ------------------------------------------------ */
bytes4 constant _INVALID_SIGNER_SELECTOR_ = 0x815e1d64; // bytes4(keccak256("InvalidSigner()"))

library StdNotaryErrors {
    /* ------------------------------------------------ *
     *                 Notary Errors                    *
     * ------------------------------------------------ */
    error InvalidSigner();
    error InvalidOwnerMethod();
    error InvalidSignatureLength();
}
