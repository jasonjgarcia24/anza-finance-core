// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
// import "@openzeppelin/contracts/access/IAccessControl.sol";
import {LibLoanContractMetadata as Metadata} from "../libraries/LibLoanContract.sol";

interface ILoanContract {
    error InvalidTokenId(uint256 tokenId);
    error InvalidParticipant(address account);
    error InvalidFundsTransfer(uint256 amount);
    error InsufficientFunds();
    error InactiveLoanState(uint256 debtId);

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

    // function initLoanContract(
    //     Metadata.TokenData memory _tokenData,
    //     uint256 _collateralNonce,
    //     uint256 _termsExpiry,
    //     bytes calldata _borrowerSignature,
    //     bytes calldata _lenderSignature
    // ) external payable;

    function borrowerOf(uint256 _debtId) external view returns (address);

    function depositPayment(uint256 _debtId) external payable;
}
