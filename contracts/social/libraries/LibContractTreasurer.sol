// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States
} from "./LibContractMaster.sol";
import { TreasurerUtils as Utils } from "./LibContractTreasurer.sol";
import {
    StateControlUint as scUint,
    StateControlAddress as scAddress,
    StateControlUtils as scUtils
} from "../../utils/StateControl.sol";

import "../interfaces/ILoanContract.sol";
import "../../utils/BlockTime.sol";

library LibLoanTreasurey {
    using scUint for scUint.Property;

    function assessMaturity_(address _loanContractAddress) public {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);

        (,,States.LoanState _originalState) = _loanContract.loanGlobals();
        require(_originalState > States.LoanState.FUNDED, "Loan contract must be active.");
        
        (
            ,,,,,,
            scUint.Property memory _balance,
            scUint.Property memory _stopBlockstamp
        ) = _loanContract.loanProperties();

        bool _isDefaulted = Utils.isDefaulted_(
            _balance._value, _stopBlockstamp._value, _originalState
        );
        
        if (_isDefaulted) {
            _loanContract.initDefault();
            (,,States.LoanState _newState) = _loanContract.loanGlobals();
            emit States.LoanStateChanged(_originalState, _newState);
        }
    }

    function getBalance_(
        Globals.Property storage _properties,
        Globals.Global storage _globals
    )
        public
        view
        returns (uint256) 
    {
        bool _isActive = scUtils.isActive_(_globals.state, _properties.balance.getThreshold());

        return  _isActive
            ? _properties.balance.get() + TreasurerUtils.calculateInterest_(
                _properties.balance.get(),
                _properties.fixedInterestRate.get(),
                _properties.duration.get(),
                _properties.stopBlockstamp.get()
            )
            : _properties.balance.get();
    }

    function updateBalance_(
        Globals.Property storage _properties,
        Globals.Global storage _globals
    ) public {
        _properties.balance.set(
            getBalance_(_properties, _globals),
            _globals.state
        );
    }
}

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
    using scUint for scUint.Property;
    using scAddress for scAddress.Property;
    using Address for address payable;

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
            _globals.state > States.LoanState.FUNDED && _globals.state < States.LoanState.PAID,
            "The loan state must between LoanState.FUNDED and LoanState.PAID."
        );

        // Update loan contract
        uint256 _balance = _properties.balance.get() + TreasurerUtils.calculateInterest_(
            _properties.balance.get(),
            _properties.fixedInterestRate.get(),
            _properties.duration.get(),
            _properties.stopBlockstamp.get()
        );

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
}

library TreasurerUtils {
    using SafeMath for uint256;

    function calculateInterest_(
        uint256 _balance,
        uint256 _fixedInterestRate,
        uint256 _duration,
        uint256 _stopBlockstamp
    ) public view returns (uint256) {
        // Reference_Block: block.number + _duration
        // Blocks_Active: Reference_Block - _stopBlockstamp
        uint256 _daysActive = BlockTime.blocksToDays(
            (block.number + _duration) - _stopBlockstamp
        );

        uint256 _interest = _balance.mul(
            _fixedInterestRate
        ).div(100).mul(_daysActive).div(365);
        console.logUint(_interest);

        return _interest;
    }

    function isDefaulted_(
        uint256 _balance,
        uint256 _stopBlockstamp,
        States.LoanState _state
    ) public view returns (bool) {
        if (_balance == 0 || _state == States.LoanState.PAID) { return false; }
        return (block.number >= _stopBlockstamp);
    }
}
