// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States
} from "./LibContractMaster.sol";

library LibContractCollector {
    /**
     * @dev Transition the LoanContract to `LoanState.DEFAULT`. This function's call
     * should originate only from the treasurer when the LoanContract has reached 
     * maturity and has not been paid in full.
     * 
     * Requirements: None
     * 
     * Emits {LoanStateChanged} event.
     */
    function defaultContract_(
        Globals.Participants storage _participants,
        Globals.Global storage _globals
    ) public {
        States.LoanState _prevState = _globals.state;

        IAccessControl ac = IAccessControl(address(this));
        ac.revokeRole(Globals._PARTICIPANT_ROLE_, _participants.borrower);
        ac.revokeRole(Globals._COLLATERAL_APPROVER_ROLE_, _participants.borrower);

        _globals.state = States.LoanState.DEFAULT;
        emit States.LoanStateChanged(_prevState, _globals.state);
    }
}
