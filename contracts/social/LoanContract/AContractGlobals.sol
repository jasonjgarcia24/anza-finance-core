// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

abstract contract AContractGlobals {
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

    bytes32 public constant _ARBITER_ROLE_ = "ARBITER";
    bytes32 public constant _BORROWER_ROLE_ = "BORROWER";
    bytes32 public constant _LENDER_ROLE_ = "LENDER";
    bytes32 public constant _PARTICIPANT_ROLE_ = "PARTICIPANT";

    address public borrower;
    address public lender;
    address public tokenContract;
    uint256 public tokenId;
    uint256 internal priority;
    uint256 public principal;
    uint256 public fixedInterestRate;
    uint256 public duration;
    uint256 internal balance;
    bool internal borrowerSigned;
    bool internal lenderSigned;
    LoanState internal state;

    mapping(address => uint256) internal accountBalance;

    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(
        LoanState indexed prevState,
        LoanState indexed newState
    );
}