// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

interface IProposal {
    enum LoanState {
        UNDEFINED,
        NONLEVERAGED,
        UNSPONSORED,
        SPONSORED,
        FUNDED,
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
        address borrower;
        address lender;
        uint256 priority;
        uint256 principal;
        uint256 fixedInterestRate;
        uint256 duration;
        uint256 balance;
        bool borrowerSigned;
        bool lenderSigned;
        LoanState state;
    }

    /**
     * @dev Emitted when a loan lender is changed.
     */
    event LoanContractCreated(
        address indexed loanContract,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when a loan lender is changed.
     */
    event LoanLenderChanged(
        address indexed prevLender,
        address indexed newLender
    );    

    /**
     * @dev Emitted when a loan parameter is changed.
     */
    event LoanParamChanged(
        bytes32 indexed param,
        uint256 prevValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when a loan agreement state is changed.
     */
    event LoanStateChanged(
        LoanState indexed prevState,
        LoanState indexed newState
    );

    /**
     * @dev Returns the loan proposal state for `tokenContract`, `tokenId`, `loanId` loan proposal.
     *
     * Requirements: NONE
     *
     */
    function getState(address tokenContract, uint256 tokenId, uint256 loanId) external view returns (LoanState state);
}