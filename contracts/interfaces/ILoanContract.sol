// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import {LibLoanContractMetadata as Metadata} from "../libraries/LibLoanContract.sol";

interface ILoanContract {
    error InvalidTokenId(uint256 tokenId);
    error InvalidParticipant(address account);
    error InvalidFundsTransfer(uint256 amount);
    error InsufficientFunds();
    error InvalidLoanParameter(bytes4 parameter);
    error OverflowLoanTerm();
    error InactiveLoanState(uint256 debtId);
    error FailedFundsTransfer();

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

    function initLoanContract(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        bytes calldata _borrowerSignature
    ) external payable;

    function loanState(uint256 _debtId) external view returns (uint256);

    function fixedInterestRate(uint256 _debtId) external view returns (uint256);

    function loanStart(uint256 _debtId) external view returns (uint256);

    function loanClose(uint256 _debtId) external view returns (uint256);

    function borrower(uint256 _debtId) external view returns (address);

    function depositPayment(uint256 _debtId) external payable;

    function withdrawPayment(uint256 _amount) external returns (bool);
}
