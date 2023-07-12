// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_} from "@lending-constants/LoanContractRoles.sol";
import "@markets-constants/AnzaDebtMarketRoles.sol";

import {IAnzaDebtMarketAccessController} from "@markets-access/interfaces/IAnzaDebtMarketAccessController.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AnzaDebtMarketAccessController is
    IAnzaDebtMarketAccessController,
    AccessControl
{
    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_DEBT_MARKET_, _ADMIN_);
        _setRoleAdmin(_DEBT_STOREFRONT_, _ADMIN_);
        _setRoleAdmin(_SPONSORSHIP_STOREFRONT_, _ADMIN_);
        _setRoleAdmin(_REFINANCE_STOREFRONT_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(IAnzaDebtMarketAccessController).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }
}
