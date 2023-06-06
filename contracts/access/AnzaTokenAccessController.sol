// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../../lib/forge-std/src/console.sol";

import "../domain/LoanContractRoles.sol";

import {IAnzaTokenAccessController} from "../interfaces/IAnzaTokenAccessController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AnzaTokenAccessController is
    IAnzaTokenAccessController,
    AccessControl
{
    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_LOAN_CONTRACT_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);
        _setRoleAdmin(_COLLATERAL_VAULT_, _ADMIN_);
        _setRoleAdmin(_DEBT_STOREFRONT_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(IAnzaTokenAccessController).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }
}
