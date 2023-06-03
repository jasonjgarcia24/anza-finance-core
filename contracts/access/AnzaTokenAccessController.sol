// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";

import "../domain/LoanContractRoles.sol";

import "../interfaces/IAnzaTokenAccessController.sol";
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

    // function checkBorrowerOf(
    //     address _account,
    //     uint256 _debtId
    // ) external view returns (bool) {
    //     return
    //         hasRole(keccak256(abi.encodePacked(_account, _debtId)), _account);
    // }
}
