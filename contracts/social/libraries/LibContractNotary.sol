// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    LibContractGlobals as Globals,
    LibContractStates as States
} from "./LibContractMaster.sol";
import "../../utils/StateControl.sol";

library LibContractNotary {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;

    /**
     * @dev The borrower signs the loan contract and transfers the collateral token.
     *
     * Requirements:
     *
     * - The borrower must not be signed off.
     * - The loan state must be les than `LoanState.NONLEVERAGED`.
     *
     * Emits {LoanStateChanged} events.
     */
    function signBorrower_(
        Globals.Participants storage _participants,
        Globals.Property storage _properties,
        Globals.Global storage _globals
    ) public {
        require(
            _properties.borrowerSigned.get() == false,
            "The borrower must not currently be signed off."
        );
        States.LoanState _prevState = _globals.state;

        // Update loan contract
        IAccessControl ac = IAccessControl(address(this));
        _properties.borrowerSigned.set(true, _globals.state);
        ac.grantRole(Globals._PARTICIPANT_ROLE_, _participants.borrower);

        _globals.state = _globals.state > States.LoanState.NONLEVERAGED
            ? _properties.lenderSigned.get()
                ? States.LoanState.FUNDED
                : States.LoanState.UNSPONSORED
            : _globals.state;

        emit States.LoanStateChanged(_prevState, _globals.state);
    }
    
    /**
     * @dev Withdraws the borrower's collateralized token from the loan contract.
     *
     * Requirements:
     *
     * - The borrower must be signed off.
     * - The loan state must be greater than `LoanState.NONLEVERAGED`.
     * - The loan state must be less than `LoanState.FUNDED`.
     *
     * Emits {LoanStateChanged} events.
     */
    function unsignBorrower_(
        Globals.Property storage _properties,
        Globals.Global storage _globals
    ) public {
        require(
            _properties.borrowerSigned.get() == true,
            "The borrower must currently be signed off."
        );
        // Update loan contract
        _properties.borrowerSigned.set(false, _globals.state);

        // No state change required
    }

    /**
     * @dev The lender signs and funds the loan contract.
     *
     * Requirements:
     *
     * - The lender must not be signed off.
     * - The loan state must be less than `LoanState.FUNDED`.
     * - Paid value and the account balance must be at least the loan principal.
     *
     * Emits {LoanStateChanged} events.
     */
    function signLender_(
        Globals.Property storage _properties,
        Globals.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) public {
        require(
            _properties.lenderSigned.get() == false,
            "The lender must not currently be signed off."
        );
        require(
            msg.value + _accountBalance[msg.sender] >= _properties.principal.get(),
            "Paid value and the account balance must be at least the loan principal."
        );
        States.LoanState _prevState = _globals.state;

        // Update loan contract
        IAccessControl ac = IAccessControl(address(this));
        _properties.lender.set(msg.sender, _globals.state);
        _properties.lenderSigned.set(true, _globals.state);
        ac.grantRole(Globals._PARTICIPANT_ROLE_, _properties.lender.get());
        _globals.state = States.LoanState.SPONSORED;

        emit States.LoanStateChanged(_prevState, _globals.state);
    }

    /**
     * @dev Remove lender signoff for loan agreement.
     *
     * Requirements:
     *
     * Emits {LoanStateChanged} events.
     */
    function _unsignLender(
        Globals.Property storage _properties,
        Globals.Global storage _globals
    ) public {
        require(
            _properties.lenderSigned.get() == true,
            "The lender must currently be signed off."
        );
        States.LoanState _prevState = _globals.state;

        // Update loan agreement
        _properties.lender.set(address(0), _globals.state);
        _properties.lenderSigned.set(false, _globals.state);
        _globals.state = States.LoanState.UNSPONSORED;

        emit States.LoanStateChanged(_prevState, _globals.state);
    }
}