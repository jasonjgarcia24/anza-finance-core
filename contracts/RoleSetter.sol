// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleSetter is AccessControl {
    address public constant admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant admin_hashed = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    bytes32 public constant admin_role = "ADMIN";
    bytes32 public constant admin_hashed_role = keccak256("ADMIN");

    constructor() {
        _setRoleAdmin(admin_role, admin_role);
        _setRoleAdmin(admin_hashed_role, admin_hashed_role);

        _grantRole(admin_role, admin);
        _grantRole(admin_hashed_role, admin_hashed);
    }
}
