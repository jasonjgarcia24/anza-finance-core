// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States
} from "./LibContractMaster.sol";
import { StateControlUint, StateControlAddress } from "../../utils/StateControl.sol";

import "../../utils/BlockTime.sol";

library ERC721Transactions {
    /**
     * @dev Transfers owners of the collateral to the loan contract.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_BORROWER_ROLE_`.
     * - The loan contract state must be `LoanState.NONLEVERAGED`.
     *
     * Emits {LoanStateChanged} event.
     */
    function depositCollateral_(
        Globals.Participants storage _participants, Globals.Global storage _globals
    ) public {
        IERC721 _erc721 = IERC721(_participants.tokenContract);
        require(
            _erc721.ownerOf(_participants.tokenId) == _participants.borrower,
            "The borrower is not the token owner."
        );
        States.LoanState _prevState = _globals.state;

        // Transfer ERC721 token to loan contract
        _erc721.safeTransferFrom(
            _participants.borrower, address(this), _participants.tokenId
        );

        // Update loan contract
        IAccessControl ac = IAccessControl(address(this));
        ac.revokeRole(Globals._COLLATERAL_OWNER_ROLE_, _globals.factory);
        ac.revokeRole(Globals._COLLATERAL_CUSTODIAN_ROLE_, _globals.factory);
        ac.revokeRole(Globals._COLLATERAL_CUSTODIAN_ROLE_, _participants.borrower);

        ac.grantRole(Globals._COLLATERAL_CUSTODIAN_ROLE_, address(this));

        _globals.state = _globals.state > States.LoanState.UNSPONSORED
            ? _globals.state
            : States.LoanState.UNSPONSORED;

        emit States.LoanStateChanged(_prevState, _globals.state);
    }

    /**
     * @dev Transfers ownership of the collateral to the borrower.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_COLLATERAL_OWNER_ROLE_` (handled in the
     *   calling function).
     * - The loan contract must be retainable.
     *
     * Emits {LoanStateChanged} event.
     */
    function revokeCollateral_(
        Globals.Participants storage _participants, Globals.Global storage _globals
    ) public {
        require(__isRetainable(_globals), "The loan state must be retainable.");
        States.LoanState _prevState = _globals.state;

        // Transfer token to borrower
        IERC721(_participants.tokenContract).safeTransferFrom(
            address(this), _participants.borrower, _participants.tokenId
        );

        // Update loan contract
        IAccessControl ac = IAccessControl(address(this));
        ac.revokeRole(Globals._COLLATERAL_OWNER_ROLE_, address(this));
        ac.revokeRole(Globals._COLLATERAL_CUSTODIAN_ROLE_, address(this));

        ac.grantRole(Globals._COLLATERAL_OWNER_ROLE_, _participants.borrower);
        ac.grantRole(Globals._COLLATERAL_CUSTODIAN_ROLE_, _participants.borrower);

        _globals.state = States.LoanState.NONLEVERAGED;

        emit States.LoanStateChanged(_prevState, _globals.state);
    }
        
    /**
     * @dev The loan contract is considered retainable if the status is inclusively
     * between UNSPONSORED and FUNDED or it is PAID. "Retainable" refers to the
     * borrowe retaining official/sole ownership of the collateralized NFT. 
     *
     * Requirements: NONE
     */
    function __isRetainable(Globals.Global memory _globals) private pure returns (bool) {
        bool _isPending = _globals.state >= States.LoanState.UNSPONSORED && _globals.state <= States.LoanState.FUNDED;
        bool _isPaid = _globals.state == States.LoanState.PAID;

        return _isPending || _isPaid;
    }
}

library ERC20Transactions {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using Address for address payable;
    using SafeMath for uint256;

    /**
     * @dev Emitted when loan contract funding is deposited.
     */
    event Deposited(address indexed payee, uint256 weiAmount);

    /**
     * @dev Emitted when loan contract funding is withdrawn.
     */
    event Withdrawn(address indexed payee, uint256 weiAmount);

    /**
     * @dev Funds the loan contract.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_LENDER_ROLE_`.
     * - The loan contract state must be `LoanState.SPONSORED`.
     *
     * Emits {LoanStateChanged} and {Deposited} events.
     */
    function depositFunding_(
        Globals.Property storage _properties,
        Globals.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) public {
        require(
            msg.sender == _properties.lender.get(),
            "The caller must be the lender."
        );
        require(
            _globals.state == States.LoanState.SPONSORED,
            "The loan state must be LoanState.SPONSORED."
        );
        States.LoanState _prevState = _globals.state;

        _accountBalance[_properties.lender.get()] += msg.value;
        require(
            _accountBalance[_properties.lender.get()] >= _properties.principal.get(),
            "The caller's account balance is insufficient."
        );

        // Update loan contract
        _globals.state = States.LoanState.FUNDED;
        _accountBalance[_properties.lender.get()] += _properties.principal.get();

        emit States.LoanStateChanged(_prevState, _globals.state);
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Defunds the loan contract.
     *
     * Requirements:
     *
     * - The loan contract state must be LoanState.FUNDED.
     *
     * Emits {LoanStateChanged} event.
     */
    function revokeFunding_(
        Globals.Property storage _properties,
        Globals.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) public {
        require(
            _globals.state == States.LoanState.FUNDED,
            "The loan state must be LoanState.FUNDED."
        );
        States.LoanState _prevState = _globals.state;

        // Update loan contract
        _globals.state = States.LoanState.SPONSORED;
        _accountBalance[_properties.lender.get()] += _properties.principal.get();

        emit States.LoanStateChanged(_prevState, _globals.state);
    }
    
    /**
     * @dev Funds the loan contract.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_LENDER_ROLE_`.
     * - The loan contract state must be `LoanState.SPONSORED`.
     *
     * Emits {LoanStateChanged} and {Deposited} events.
     */
    function depositPayment_(
        Globals.Participants storage _participants,
        Globals.Property storage _properties,
        Globals.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) public {
        require(
            _globals.state > States.LoanState.FUNDED,
            "The loan state must greater than LoanState.FUNDED."
        );

        // Update loan contract
        uint256 _balance = _properties.balance.get() + __calculateInterest(_properties);

        if (_balance >= msg.value) {
            _properties.balance.set(_balance - msg.value, _globals.state);
            _accountBalance[_participants.treasurey] += msg.value;
            _accountBalance[_properties.lender.get()] += msg.value;
        } else {
            _properties.balance.set(0, _globals.state);
            _accountBalance[_participants.borrower] = msg.value - _balance;
            _accountBalance[_participants.treasurey] += _balance;
            _accountBalance[_properties.lender.get()] += _balance;
            _globals.state = States.LoanState.PAID;
        }

        if (_properties.balance.get() == 0) {
            States.LoanState _prevState = _globals.state;
            _globals.state = States.LoanState.PAID;
            emit States.LoanStateChanged(_prevState, _globals.state);
        }

        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Withdraws funds from loan.
     * @param _payee The address whose funds will be withdrawn and transferred to.
     * 
     * Requirements: NONE
     * 
     * Emits a {Withdrawn} event.
     */
    function withdrawFunds_(
        address payable _payee,
        mapping(address => uint256) storage _accountBalance
    ) public {     
        uint256 _payment = _accountBalance[_payee];
        _accountBalance[_payee] = 0;

        _payee.sendValue(_payment);

        emit Withdrawn(_payee, _payment);
    }

    function __calculateInterest(Globals.Property storage _properties) private view returns (uint256) {
        // Reference_Block: block.number + _properties.duration.get()
        // Blocks_Active: Reference_Block - _properties.stopBlockstamp.get()
        uint256 _daysActive = BlockTime.blocksToDays(
            (
                block.number + _properties.duration.get()
            ) - _properties.stopBlockstamp.get()
        );
        uint256 _interest = _properties.balance.get().mul(
            _properties.fixedInterestRate.get()
        ).div(100).mul(_daysActive).div(365);

        return _interest;
    }
}
