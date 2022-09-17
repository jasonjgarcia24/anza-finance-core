// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILoanAgreement {
    enum LoanState {
        UNDEFINED,
        PENDING_UNSPONSORED,
        PENDING_SPONSORED,
        ACTIVE_GRACE_COMMITTED,
        ACTIVE_GRACE_OPEN,
        ACTIVE_COMMITTED,
        ACTIVE_OPEN,
        PAID,
        DEFAULT,
        AUCTION,
        CLOSED
    }

    struct LoanAgreement {
        address lender;
        uint256 priority;
        uint256 principal;
        uint256 fixedInterestRate;
        uint256 duration;
        LoanState state;
    }
}