// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../utils/StateControl.sol";
import "../../utils/BlockTime.sol";
import "hardhat/console.sol";

abstract contract AContractGlobals is AccessControl {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

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

    bytes32 internal constant _ADMIN_ROLE_ = "ADMIN";
    bytes32 internal constant _ARBITER_ROLE_ = "ARBITER";
    bytes32 internal constant _BORROWER_ROLE_ = "BORROWER";
    bytes32 internal constant _LENDER_ROLE_ = "LENDER";
    bytes32 internal constant _PARTICIPANT_ROLE_ = "PARTICIPANT";
    bytes32 internal constant _COLLATERAL_CUSTODIAN_ROLE_ = "COLLATERAL_CUSTODIAN";
    bytes32 internal constant _COLLATERAL_OWNER_ROLE_ = "COLLATERAL_OWNER";

    address internal factory;
    address public borrower;
    address public tokenContract;
    uint256 public tokenId;
    uint256 public priority;

    StateControlAddress.Property public lender;
    StateControlUint.Property public principal;
    StateControlUint.Property public fixedInterestRate;
    StateControlUint.Property public duration;
    StateControlBool.Property public borrowerSigned;
    StateControlBool.Property public lenderSigned;
    StateControlUint.Property public balance;
    StateControlUint.Property public stopBlockstamp;

    LoanState public state;

    mapping(address => uint256) internal accountBalance;

    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(LoanState indexed prevState, LoanState indexed newState);
    
    /**
     * @dev The loan contract is considered retainable if the status is inclusively
     * between UNSPONSORED and FUNDED or it is PAID. "Retainable" refers to the
     * borrowe retaining official/sole ownership of the collateralized NFT. 
     *
     * Requirements: NONE
     */
    function isRetainable() internal view returns (bool) {
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