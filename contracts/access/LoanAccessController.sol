// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../domain/LoanContractRoles.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract LoanAccessController is AccessControl {
    address public immutable collateralVault;

    constructor(address _collateralVault) {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);
        _setRoleAdmin(_COLLECTOR_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);

        collateralVault = _collateralVault;
    }
}
