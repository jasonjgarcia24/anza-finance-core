// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoanContract {
    error InvalidCollateral();
    error InvalidParticipant();
    error FailedFundsTransfer();
    error ExceededRefinanceLimit();

    event LoanContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId
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

    function totalDebts() external returns (uint256);

    function debtIds(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtIdx
    ) external returns (uint256);

    function debtBalanceOf(uint256 _debtId) external view returns (uint256);

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function getCollateralDebtId(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function initLoanContract(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        bytes calldata _borrowerSignature
    ) external payable;

    function initLoanContract(
        bytes32 _contractTerms,
        uint256 _debtId,
        bytes calldata _borrowerSignature
    ) external payable;

    function mintReplica(uint256 _debtId) external;
}
