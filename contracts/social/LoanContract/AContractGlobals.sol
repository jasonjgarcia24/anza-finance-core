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

    bytes32 public constant _ADMIN_ROLE_ = "ADMIN";
    bytes32 public constant _ARBITER_ROLE_ = "ARBITER";
    bytes32 public constant _BORROWER_ROLE_ = "BORROWER";
    bytes32 public constant _LENDER_ROLE_ = "LENDER";
    bytes32 public constant _PARTICIPANT_ROLE_ = "PARTICIPANT";
    bytes32 public constant _COLLATERAL_CUSTODIAN_ROLE_ = "COLLATERAL_CUSTODIAN";
    bytes32 public constant _COLLATERAL_OWNER_ROLE_ = "COLLATERAL_OWNER";

    address internal factory;
    address internal borrower_;
    address internal tokenContract_;
    uint256 internal tokenId_;

    StateControlAddress.Property internal lender_;
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
        return borrower_;
    }

    function lender() external view returns (address) {
        return lender_.get();
    }

    function tokenContract() external view returns (address) {
        return tokenContract_;
    }

    function tokenId() external view returns (uint256) {
        return tokenId_;
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

    /**
     * @dev Returns the terms of the loan contract.
     *
     * Requirements: NONE
     */
    function getLoanTerms() external view returns (uint256[3] memory) {
        return [principal_.get(), fixedInterestRate_.get(), duration_.get()];
    }
    
    /**
     * @dev The loan contract is considered retainable if the status is inclusively
     * between UNSPONSORED and FUNDED or it is PAID. "Retainable" refers to the
     * borrowe retaining official/sole ownership of the collateralized NFT. 
     *
     * Requirements: NONE
     */
    function isRetainable() public view returns (bool) {
        bool _isPending = state >= LoanState.UNSPONSORED && state <= LoanState.FUNDED;
        bool _isPaid = state == LoanState.PAID;

        return _isPending || _isPaid;
    }

    /**
     * @dev Returns `true` if msg.sender has been granted `role`.
     */
    function _hasRole(bytes32 role) internal view virtual returns (bool) {
        return hasRole(role, _msgSender());
    }
}