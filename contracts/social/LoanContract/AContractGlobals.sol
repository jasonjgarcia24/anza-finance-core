// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../utils/StateControl.sol";
import "hardhat/console.sol";

abstract contract AContractGlobals is AccessControl {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;

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

    StateControlAddress.Property internal borrower_;
    StateControlAddress.Property internal lender_;
    StateControlAddress.Property internal tokenContract_;
    StateControlUint.Property internal tokenId_;
    StateControlUint.Property internal principal_;
    StateControlUint.Property internal fixedInterestRate_;
    StateControlUint.Property internal duration_;
    StateControlBool.Property internal borrowerSigned_;
    StateControlBool.Property internal lenderSigned_;

    LoanState internal state;

    mapping(address => uint256) internal accountBalance;

    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(LoanState indexed prevState, LoanState indexed newState);

    function borrower() external view returns (address) {
        return borrower_.get();
    }

    function lender() external view returns (address) {
        return lender_.get();
    }

    function tokenContract() external view returns (address) {
        return tokenContract_.get();
    }

    function tokenId() external view returns (uint256) {
        return tokenId_.get();
    }

    function principal() external view returns (uint256) {
        return principal_.get();
    }

    function fixedInterestRate() external view returns (uint256) {
        return fixedInterestRate_.get();
    }

    function duration() external view returns (uint256) {
        return duration_.get();
    }

    function borrowerSigned() external view returns (bool) {
        return borrowerSigned_.get();
    }

    function lenderSigned() external view returns (bool) {
        return lenderSigned_.get();
    }
}