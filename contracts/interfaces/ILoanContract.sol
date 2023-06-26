// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanContract {
    event ContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId,
        uint256 activeLoanIndex
    );

    event ProposalRevoked(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed collateralNonce,
        bytes32 contractTerms
    );

    event PaymentSubmitted(
        uint256 indexed debtId,
        address indexed borrower,
        address indexed lender,
        uint256 amount
    );

    event LoanBorrowerChanged(
        uint256 indexed debtId,
        address indexed newBorrower,
        address indexed oldBorrower
    );

    function initContract(
        address _collateralAddress,
        uint256 _collateralId,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) external payable;

    function initContract(
        uint256 _debtId,
        address _borrower,
        address _lender,
        bytes32 _contractTerms
    ) external payable;

    function initContract(
        uint256 _debtId,
        address _borrower,
        address _lender
    ) external payable;
}
