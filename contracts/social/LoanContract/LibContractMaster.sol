// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Interfaces/ILoanContract.sol";
import "../../utils/StateControl.sol";
import "../../utils/BlockTime.sol";

library LibContractGlobals {
    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(LoanState indexed prevState, LoanState indexed newState);

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
    
    // bytes4 internal  constant _ADMIN_ROLE_ = 0x00000001;
    bytes32 internal  constant _ADMIN_ROLE_ = "ADMIN";
    bytes32 internal constant _ARBITER_ROLE_ = "ARBITER";
    bytes32 internal constant _BORROWER_ROLE_ = "BORROWER";
    bytes32 internal constant _LENDER_ROLE_ = "LENDER";
    bytes32 internal constant _PARTICIPANT_ROLE_ = "PARTICIPANT";
    bytes32 internal constant _COLLATERAL_CUSTODIAN_ROLE_ = "COLLATERAL_CUSTODIAN";
    bytes32 internal constant _COLLATERAL_OWNER_ROLE_ = "COLLATERAL_OWNER";

    struct Participants {
        address borrower;
        address tokenContract;
        uint256 tokenId;
    }

    struct Property {
        StateControlAddress.Property lender;
        StateControlUint.Property principal;
        StateControlUint.Property fixedInterestRate;
        StateControlUint.Property duration;
        StateControlBool.Property borrowerSigned;
        StateControlBool.Property lenderSigned;
        StateControlUint.Property balance;
        StateControlUint.Property stopBlockstamp;
    }

    struct Global {
        address factory;
        uint256 priority;
        LoanState state;
    }

    /**
     * @dev Emitted when loan contract term(s) are updated.
     */
    event TermsChanged(
        string[] params,
        uint256[] prevValues,
        uint256[] newValues
    );
}

library LibContractInit {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

    function _initializeContract(
        LibContractGlobals.Participants storage _participants,
        LibContractGlobals.Property storage _property,
        LibContractGlobals.Global storage _globals,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) internal {
        // Initialize state controlled variables
        _participants.borrower = IERC721(_tokenContract).ownerOf(_tokenId);
        _participants.tokenContract = _tokenContract;
        _participants.tokenId = _tokenId;

        uint256 _fundedState = uint256(LibContractGlobals.LoanState.FUNDED);
        _property.lender.init(address(0), _fundedState);
        _property.principal.init(_principal, _fundedState);
        _property.fixedInterestRate.init(_fixedInterestRate, _fundedState);
        _property.duration.init(_duration.daysToBlocks(), _fundedState);
        _property.borrowerSigned.init(false, _fundedState);
        _property.lenderSigned.init(false, _fundedState);

        _property.balance.init(0, uint256(LibContractGlobals.LoanState.PAID));
        _property.stopBlockstamp.init(type(uint256).max, _fundedState);

        // Set state variables
        IAccessControl ac = IAccessControl(address(this));
        _globals.factory = msg.sender;
        _globals.priority = _priority;
        _globals.state = LibContractGlobals.LoanState.NONLEVERAGED;

        // Set roles
        ac.grantRole(LibContractGlobals._ARBITER_ROLE_, address(this));
        ac.grantRole(LibContractGlobals._BORROWER_ROLE_, _participants.borrower);
        ac.grantRole(LibContractGlobals._COLLATERAL_OWNER_ROLE_, _globals.factory);
        ac.grantRole(LibContractGlobals._COLLATERAL_OWNER_ROLE_, _participants.borrower);
        ac.grantRole(LibContractGlobals._COLLATERAL_CUSTODIAN_ROLE_, _globals.factory);
        ac.grantRole(LibContractGlobals._COLLATERAL_CUSTODIAN_ROLE_, _participants.borrower);
    }
}

library LibContractActivate {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;

    /**
     * @dev The loan contract becomes active and the funds are withdrawable.
     *
     * Requirements:
     *
     * - LoanState must be FUNDED (check with caller function).
     * - Lender and borrower must be signed off.
     *
     * Emits {LoanStateChanged} events.
     */
    function _activateLoan(
        LibContractGlobals.Participants storage _participants,
        LibContractGlobals.Property storage _properties,
        LibContractGlobals.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) internal {
        LibContractGlobals.LoanState _prevState = _globals.state;

        // Update loan contract and activate loan
        _globals.state = LibContractGlobals.LoanState.ACTIVE_OPEN;
        _properties.balance.set(_properties.principal.get(), uint256(_globals.state));
        _accountBalance[_properties.lender.get()] -= _properties.principal.get();
        _accountBalance[_participants.borrower] += _properties.principal.get();

        emit LibContractGlobals.LoanStateChanged(_prevState, _globals.state);
    }
}