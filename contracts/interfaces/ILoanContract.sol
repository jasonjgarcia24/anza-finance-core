// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanContract {
    error InvalidIndex();
    error InvalidCollateral();
    error FailedFundsTransfer();
    error ExceededRefinanceLimit();

    struct DebtMap {
        uint256 debtId;
        uint256 collateralNonce;
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

    function debtBalance(uint256 _debtId) external view returns (uint256);

    function collateralDebtBalance(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function collateralDebtCount(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function collateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function collateralDebtAt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _index
    ) external view returns (DebtMap memory);

    function initLoanContract(
        address _collateralAddress,
        uint256 _collateralId,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) external payable;

    function initLoanContract(
        uint256 _debtId,
        address _borrower,
        address _lender,
        bytes32 _contractTerms
    ) external payable;

    function initLoanContract(
        uint256 _debtId,
        address _borrower,
        address _lender
    ) external payable;
}
