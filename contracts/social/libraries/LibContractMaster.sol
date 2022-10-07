// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../interfaces/ILoanContract.sol";
import "../../utils/StateControl.sol";
import "../../utils/BlockTime.sol";

library LibContractGlobals {
    bytes32 internal constant _ADMIN_ROLE_ = "ADMIN";
    bytes32 internal constant _TREASURER_ROLE_ = "TREASURER";
    bytes32 internal constant _ARBITER_ROLE_ = "ARBITER";
    bytes32 internal constant _BORROWER_ROLE_ = "BORROWER";
    bytes32 internal constant _LENDER_ROLE_ = "LENDER";
    bytes32 internal constant _COLLECTOR_ROLE_ = "COLLECTOR";
    bytes32 internal constant _PARTICIPANT_ROLE_ = "PARTICIPANT";
    bytes32 internal constant _COLLATERAL_CUSTODIAN_ROLE_ = "COLLATERAL_CUSTODIAN";
    bytes32 internal constant _COLLATERAL_OWNER_ROLE_ = "COLLATERAL_OWNER";

    struct Participants {
        address treasurey;
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
        LibContractStates.LoanState state;
    }
}

library LibContractStates {
    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(
        LoanState indexed prevState,
        LoanState indexed newState
    );

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
        COLLECTION,
        AUCTION,
        AWARDED,
        CLOSED
    }
}

library LibContractInit {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

    function initializeContract_(
        LibContractGlobals.Participants storage _participants,
        LibContractGlobals.Property storage _property,
        LibContractGlobals.Global storage _globals,
        address _treasurey,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) public {
        // Initialize state controlled variables
        _participants.treasurey = _treasurey;
        _participants.borrower = IERC721(_tokenContract).ownerOf(_tokenId);
        _participants.tokenContract = _tokenContract;
        _participants.tokenId = _tokenId;

        _property.lender.init(address(0), LibContractStates.LoanState.FUNDED);
        _property.principal.init(_principal, LibContractStates.LoanState.FUNDED);
        _property.fixedInterestRate.init(_fixedInterestRate, LibContractStates.LoanState.FUNDED);
        _property.duration.init(_duration.daysToBlocks(), LibContractStates.LoanState.FUNDED);
        _property.borrowerSigned.init(false, LibContractStates.LoanState.FUNDED);
        _property.lenderSigned.init(false, LibContractStates.LoanState.FUNDED);

        _property.balance.init(0, LibContractStates.LoanState.PAID);
        _property.stopBlockstamp.init(type(uint256).max, LibContractStates.LoanState.FUNDED);

        // Set state variables
        IAccessControl ac = IAccessControl(address(this));
        _globals.factory = msg.sender;
        _globals.priority = _priority;
        _globals.state = LibContractStates.LoanState.NONLEVERAGED;

        // Set roles
        ac.grantRole(LibContractGlobals._ARBITER_ROLE_, address(this));
        ac.grantRole(LibContractGlobals._BORROWER_ROLE_, _participants.borrower);
        ac.grantRole(LibContractGlobals._COLLATERAL_OWNER_ROLE_, _globals.factory);
        ac.grantRole(LibContractGlobals._COLLATERAL_OWNER_ROLE_, _participants.borrower);
        ac.grantRole(LibContractGlobals._COLLATERAL_CUSTODIAN_ROLE_,_globals.factory);
        ac.grantRole(LibContractGlobals._COLLATERAL_CUSTODIAN_ROLE_, _participants.borrower);
    }
}

library LibContractUpdate {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using BlockTime for uint256;

    /**
     * @dev Emitted when loan contract term(s) are updated.
     */
    event TermsChanged(
        string[] params,
        uint256[] prevValues,
        uint256[] newValues
    );

    function updateTerms_(
        LibContractGlobals.Property storage _property,
        LibContractGlobals.Global storage _globals,
        string[] memory _params,
        uint256[] memory _newValues
    ) public {
        require(
            _params.length == _newValues.length,
            "Input array parameters must be of equal length."
        );
        require(
            _params.length <= 3,
            "Input array parameters must be no more than 3."
        );

        uint256[] memory _prevValues = new uint256[](_params.length);

        for (uint256 i; i < _params.length; i++) {
            bytes32 _thisParam = keccak256(bytes(_params[i]));

            if (_thisParam == keccak256(bytes("principal"))) {
                _prevValues[i] = _property.principal.get();
                _property.principal.set(_newValues[i], _globals.state);
            } else if (_thisParam == keccak256(bytes("fixed_interest_rate"))) {
                _prevValues[i] = _property.fixedInterestRate.get();
                _property.fixedInterestRate.set(_newValues[i], _globals.state);
            } else if (_thisParam == keccak256(bytes("duration"))) {
                _prevValues[i] = _property.duration.get();
                _newValues[i] = _newValues[i].daysToBlocks();
                _property.duration.set(_newValues[i], _globals.state);
            } else {
                revert(
                    "`_params` must include strings 'principal', 'fixed_interest_rate', or 'duration' only."
                );
            }
        }

        emit TermsChanged(_params, _prevValues, _newValues);
    }

    function checkActiveState_(LibContractGlobals.Global storage _globals) public view {
        require(
            _globals.state > LibContractStates.LoanState.FUNDED && _globals.state < LibContractStates.LoanState.PAID,
            "Loan state must between FUNDED and PAID exclusively."
        );
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
    function activateLoan_(
        LibContractGlobals.Participants storage _participants,
        LibContractGlobals.Property storage _properties,
        LibContractGlobals.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) public {
        LibContractStates.LoanState _prevState = _globals.state;

        // Update loan contract and activate loan
        _globals.state = LibContractStates.LoanState.ACTIVE_OPEN;
        _properties.balance.set(_properties.principal.get(), _globals.state);
        _accountBalance[_properties.lender.get()] -= _properties
            .principal
            .get();
        _accountBalance[_participants.borrower] += _properties.principal.get();

        emit LibContractStates.LoanStateChanged(_prevState, _globals.state);
    }
}
