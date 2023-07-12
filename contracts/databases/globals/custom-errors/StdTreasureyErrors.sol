// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *        Loan Treasurey Custom Error Selectors     *
 * ------------------------------------------------ */
bytes4 constant _INVALID_FUNDS_TRANSFER_SELECTOR_ = 0x0ba7499a; // bytes4(keccak256("InvalidFundsTransfer()"))
bytes4 constant _FAILED_PURCHASE_SELECTOR_ = 0xb6468e52; // bytes4(keccak256("FailedPurchase()"))

library StdTreasureyErrors {
    /* ------------------------------------------------ *
     *          Loan Treasurey Custom Errors            *
     * ------------------------------------------------ */
    error InvalidFundsTransfer();
    error FailedWithdrawal();
    error FailedPurchase();
}
