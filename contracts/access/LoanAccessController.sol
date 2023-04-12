// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../domain/LoanContractRoles.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract LoanAccessController is AccessControl {
    address public immutable collateralVault;

    constructor(address _collateralVault) {
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(TREASURER, ADMIN);
        _setRoleAdmin(COLLECTOR, ADMIN);

        _grantRole(ADMIN, msg.sender);

        collateralVault = _collateralVault;
    }
}
