// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import {_ADMIN_, _TREASURER_} from "@lending-constants/LoanContractRoles.sol";

import {IManagerAccessController} from "./interfaces/IManagerAccessController.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract ManagerAccessController is
    IManagerAccessController,
    AccessControl
{
    address internal _loanTreasurerAddress;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl) returns (bool) {
        return
            _interfaceId == type(IManagerAccessController).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /**
     * Returns the Loan Treasurer contract address.
     */
    function loanTreasurer() external view returns (address) {
        return _loanTreasurerAddress;
    }

    /**
     * Overriding the default grantRole function to set the Loan Treasurer
     * address as the _TREASURER_ role holder.
     *
     * @notice Internal function without access restriction.
     *
     * @param _role The role to grant.
     * @param _account The address to grant the role to.
     */
    function _grantRole(
        bytes32 _role,
        address _account
    ) internal virtual override(AccessControl) {
        (_role == _TREASURER_)
            ? __setLoanTreasurer(_account)
            : super._grantRole(_role, _account);
    }

    /**
     * Sets the Loan Treasurer address, revokes the _TREASURER_ role from the
     * previous Loan Treasurer, and grants the _TREASURER_ role to the new loan
     * treasurer address.
     *
     * @notice Private function without access restriction.
     *
     * @param _treasurer The address of the new loan treasurer.
     */
    function __setLoanTreasurer(address _treasurer) private {
        _revokeRole(_TREASURER_, _loanTreasurerAddress);
        super._grantRole(_TREASURER_, _treasurer);

        _loanTreasurerAddress = _treasurer;
    }
}
