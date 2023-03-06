// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/RoleSetter.sol";

contract RoleSetterTest is Test {
    RoleSetter public roleSetter;

    function setUp() public {
        roleSetter = new RoleSetter();
    }

    function testPrintRoles() public view {
        console.logBytes32(roleSetter.admin_role());
        console.logBytes32(roleSetter.admin_hashed_role());
    }

    function testHasRole() public {
        assertTrue(
            roleSetter.hasRole(roleSetter.admin_role(), roleSetter.admin())
        );
        assertTrue(
            roleSetter.hasRole(roleSetter.admin_hashed_role(), roleSetter.admin_hashed())
        );

        assertFalse(
            roleSetter.hasRole(roleSetter.admin_role(), roleSetter.admin_hashed())
        );
        assertFalse(
            roleSetter.hasRole(roleSetter.admin_hashed_role(), roleSetter.admin())
        );
    }
}
