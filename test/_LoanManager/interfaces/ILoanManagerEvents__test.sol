// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanManagerEvents {
    event LoanTermsRevoked(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );

    event LoanTermsReinstated(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );
}
