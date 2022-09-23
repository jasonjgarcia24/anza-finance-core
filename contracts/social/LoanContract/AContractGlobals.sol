// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../utils/StateControl.sol";
import "hardhat/console.sol";

abstract contract AContractGlobals is AccessControl {
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
        AWARDED,
        CLOSED
    }

    bytes32 public constant _ARBITER_ROLE_ = "ARBITER";
    bytes32 public constant _BORROWER_ROLE_ = "BORROWER";
    bytes32 public constant _LENDER_ROLE_ = "LENDER";
    bytes32 public constant _PARTICIPANT_ROLE_ = "PARTICIPANT";
    bytes32 public constant _COLLATERAL_APPROVER_ROLE_ = "COLLATERAL_APPROVER";
    bytes32 public constant _COLLATERAL_OWNER_ROLE_ = "COLLATERAL_OWNER";

    StateControlAddress.Property public borrower;
    StateControlAddress.Property public lender;
    StateControlAddress.Property public tokenContract;
    StateControlUint.Property public tokenId;
    StateControlUint.Property public principal;
    StateControlUint.Property public fixedInterestRate;
    StateControlUint.Property public duration;
    StateControlUint.Property public balance;
    StateControlBool.Property public borrowerSigned;
    StateControlBool.Property public lenderSigned;

    LoanState internal state;

    mapping(address => uint256) internal accountBalance;

    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(LoanState indexed prevState, LoanState indexed newState);
}