// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoanContract {
    error InvalidCollateral();
    error FailedFundsTransfer();
    error ExceededRefinanceLimit();

    struct Debt {
        uint256 debtId;
        uint256 collateralNonce;
        uint256 activeLoanIndex;
    }

    event LoanContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId,
        uint256 activeLoanIndex
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

    function debts(
        address _collateralAddress,
        uint256 _collateralId
    ) external returns (uint256, uint256, uint256);

    function debtIdBranch(
        uint256 _childDebtId
    ) external returns (uint256, uint256, uint256);

    function debtBalanceOf(uint256 _debtId) external view returns (uint256);

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function getCollateralDebtId(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function getActiveLoanIndex(
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

    function initLoanContract(
        uint256 _debtId,
        address _borrower,
        address _lender
    ) external payable;

    function mintReplica(uint256 _debtId) external;
}
