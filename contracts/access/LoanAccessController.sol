// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {LibOfficerRoles as Roles} from "../libraries/LibLoanContract.sol";

contract LoanAccessController is AccessControl {
    address public immutable collateralVault;

    constructor(address _collateralVault) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);
        _setRoleAdmin(Roles._COLLECTOR_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, msg.sender);

        collateralVault = _collateralVault;
    }
}
