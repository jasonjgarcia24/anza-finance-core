// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

bytes4 constant _FAILED_FUNDS_TRANSFER_ = 0x2ed7fc0e;

library StdMonetaryErrors {
    /* ------------------------------------------------ *
     *               Transaction Errors                 *
     * ------------------------------------------------ */
    error FailedFundsTransfer();
    error ExceededRefinanceLimit();
}
