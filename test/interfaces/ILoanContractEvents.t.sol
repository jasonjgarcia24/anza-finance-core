// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

interface ILoanContractEvents {
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

    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );
}
