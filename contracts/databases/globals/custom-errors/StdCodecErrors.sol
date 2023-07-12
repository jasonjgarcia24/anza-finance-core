// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *        Loan Codec Custom Error Selectors          *
 * ------------------------------------------------ */
bytes4 constant _INVALID_LOAN_PARAMETER_SELECTOR_ = 0x87eb23b2; // bytes4(keccak256("InvalidLoanParameter(bytes4)"))
bytes4 constant _INACTIVE_LOAN_STATE_SELECTOR_ = 0x90f54c85; // bytes4(keccak256("InactiveLoanState()"))
bytes4 constant _EXPIRED_LOAN_SELECTOR_ = 0xf342c922; // bytes4(keccak256("ExpriredLoan()"))

library StdCodecErrors {
    /* ------------------------------------------------ *
     *            Loan Codec Custom Errors              *
     * ------------------------------------------------ */
    error InvalidLoanParameter(bytes4);
    error InactiveLoanState();
    error ExpriredLoan();
}
