// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoanContract {
    error InvalidCollateral();
    error InvalidParticipant();
    error InvalidLoanParameter(bytes4 parameter);
    error InactiveLoanState();
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

    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );

    function debtIds(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtIdx
    ) external returns (uint256);

    function loanTreasurer() external returns (address);

    function anzaToken() external returns (address);

    function totalDebts() external returns (uint256);

    function maxRefinances() external returns (uint256);

    function debtBalanceOf(uint256 _debtId) external view returns (uint256);

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function getCollateralDebtId(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function getDebtTerms(uint256 _debtId) external view returns (bytes32);

    function setLoanTreasurer(address _loanTreasurer) external;

    function setAnzaToken(address _anzaToken) external;

    function setMaxRefinances(uint256 _maxRefinances) external;

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

    function loanState(uint256 _debtId) external view returns (uint256);

    function firInterval(uint256 _debtId) external view returns (uint256);

    function fixedInterestRate(uint256 _debtId) external view returns (uint256);

    function loanLastChecked(uint256 _debtId) external view returns (uint256);

    function loanStart(uint256 _debtId) external view returns (uint256);

    function loanClose(uint256 _debtId) external view returns (uint256);

    function lenderRoyalties(uint256 _debtId) external view returns (uint256);

    function activeLoanCount(uint256 _debtId) external view returns (uint256);

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) external view returns (uint256);

    function updateLoanState(uint256 _debtId) external;

    function verifyLoanActive(uint256 _debtId) external view;

    function checkLoanActive(uint256 _debtId) external view returns (bool);

    function checkLoanDefault(uint256 _debtId) external view returns (bool);

    function checkLoanExpired(uint256 _debtId) external view returns (bool);
}
