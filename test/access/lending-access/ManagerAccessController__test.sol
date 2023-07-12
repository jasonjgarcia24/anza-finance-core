// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_, _TREASURER_} from "@lending-constants/LoanContractRoles.sol";

import {ManagerAccessController} from "@lending-access/ManagerAccessController.sol";

import {Setup} from "@test-base/Setup__test.sol";

contract LoanManagerAccessContollerHarness is ManagerAccessController {
    constructor() ManagerAccessController() {}

    /* Abstract functions */
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract LoanManagerAccessControllerInit is Setup {
    LoanManagerAccessContollerHarness public loanManagerAccessControllerHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        loanManagerAccessControllerHarness = new LoanManagerAccessContollerHarness();
        vm.stopPrank();
    }
}

contract LoanManagerAccessControllerUnitTest is
    LoanManagerAccessControllerInit
{
    /* -------- DebtBookAccessController.__setLoanTreasurer() -------- */
    /**
     * Fuzz test for setting the loan treasurer address.
     *
     * @param _caller The address of the caller.
     * @param _loanTreasurerAddress The address of the LoanTreasurey
     * contract.
     * @param _alt_loanTreasurerAddress The alteranate address of the
     * LoanTreasurey contract.
     *
     * @dev Full pass if the address is set correctly.
     * @dev Full pass if the caller is the admin.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testDebtBookAccessController__Fuzz_SetLoanTreasurer(
        address _caller,
        address _loanTreasurerAddress,
        address _alt_loanTreasurerAddress
    ) public {
        vm.assume(_loanTreasurerAddress != _alt_loanTreasurerAddress);

        assertEq(
            address(loanManagerAccessControllerHarness.loanTreasurer()),
            address(0),
            "0 :: loan treasurer should be address(0)."
        );

        // Set with caller
        vm.startPrank(_caller);
        try
            loanManagerAccessControllerHarness.grantRole(
                _TREASURER_,
                _loanTreasurerAddress
            )
        {
            assertTrue(
                loanManagerAccessControllerHarness.hasRole(_ADMIN_, _caller),
                "1 :: caller should have admin role"
            );
            assertEq(
                loanManagerAccessControllerHarness.loanTreasurer(),
                _loanTreasurerAddress,
                "2 :: loan treasurer does not match expected address"
            );

            assertTrue(
                loanManagerAccessControllerHarness.hasRole(
                    _TREASURER_,
                    _loanTreasurerAddress
                ),
                "3 :: loan treasurer should have treasurer role"
            );
        } catch Error(string memory _errStr) {
            if (_caller != admin) {
                assertEq(
                    keccak256(abi.encodePacked(_errStr)),
                    keccak256(
                        abi.encodePacked(
                            getAccessControlFailMsg(_ADMIN_, _caller)
                        )
                    ),
                    "4 :: access control standard failure expected."
                );
            } else {
                unexpectedFail(
                    "not access control standard failure, should not fail.",
                    _errStr
                );
            }
        }
        vm.stopPrank();

        // Set with admin
        vm.startPrank(admin);
        assertTrue(
            loanManagerAccessControllerHarness.hasRole(_ADMIN_, admin),
            "5 :: admin should have admin role"
        );

        loanManagerAccessControllerHarness.grantRole(
            _TREASURER_,
            _loanTreasurerAddress
        );

        assertEq(
            loanManagerAccessControllerHarness.loanTreasurer(),
            _loanTreasurerAddress,
            "6 :: loan treasurer does not match expected address"
        );

        assertTrue(
            loanManagerAccessControllerHarness.hasRole(
                _TREASURER_,
                _loanTreasurerAddress
            ),
            "7 :: loan treasurer should have treasurer role"
        );

        // Change with admin
        loanManagerAccessControllerHarness.grantRole(
            _TREASURER_,
            _alt_loanTreasurerAddress
        );

        assertEq(
            loanManagerAccessControllerHarness.loanTreasurer(),
            _alt_loanTreasurerAddress,
            "8 :: alt loan treasurer does not match expected address"
        );

        assertTrue(
            loanManagerAccessControllerHarness.hasRole(
                _TREASURER_,
                _alt_loanTreasurerAddress
            ),
            "9 :: alt loan treasurer should have treasurer role"
        );

        assertFalse(
            loanManagerAccessControllerHarness.hasRole(
                _TREASURER_,
                _loanTreasurerAddress
            ),
            "10 :: loan treasurer should not have treasurer role"
        );
        vm.stopPrank();
    }

    /* ------------ DebtBookAccessController._grantRole() ------------ */
    /**
     * Fuzz test for setting the loan treasurer address via _grantRole.
     *
     * @param _caller The address of the caller.
     * @param _loanTreasurerAddress The address of the LoanTreasurey
     * contract.
     * @param _alt_loanTreasurerAddress The alteranate address of the
     * LoanTreasurey contract.
     *
     * @dev Full pass if the address is set correctly.
     * @dev Full pass if the caller is the admin.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testDebtBookAccessController__Fuzz__GrantRole(
        address _caller,
        address _loanTreasurerAddress,
        address _alt_loanTreasurerAddress
    ) public {
        vm.assume(_loanTreasurerAddress != _alt_loanTreasurerAddress);

        assertEq(
            address(loanManagerAccessControllerHarness.loanTreasurer()),
            address(0),
            "0 :: loan treasurer should be address(0)."
        );

        // Set with caller
        vm.startPrank(_caller);
        try
            loanManagerAccessControllerHarness.grantRole(
                _TREASURER_,
                _loanTreasurerAddress
            )
        {
            assertEq(
                loanManagerAccessControllerHarness.loanTreasurer(),
                _loanTreasurerAddress,
                "1 :: loan treasurer does not match expected address"
            );

            assertTrue(
                loanManagerAccessControllerHarness.hasRole(
                    _TREASURER_,
                    _loanTreasurerAddress
                ),
                "2 :: loan treasurer should have treasurer role"
            );
        } catch Error(string memory _errStr) {
            if (_caller != admin) {
                assertEq(
                    keccak256(abi.encodePacked(_errStr)),
                    keccak256(
                        abi.encodePacked(
                            getAccessControlFailMsg(_ADMIN_, _caller)
                        )
                    ),
                    "3 :: access control standard failure expected."
                );
            } else {
                unexpectedFail(
                    "not access control standard failure, should not fail.",
                    _errStr
                );
            }
        }
        vm.stopPrank();

        // Set with admin
        vm.startPrank(admin);
        loanManagerAccessControllerHarness.grantRole(
            _TREASURER_,
            _loanTreasurerAddress
        );

        assertEq(
            loanManagerAccessControllerHarness.loanTreasurer(),
            _loanTreasurerAddress,
            "4 :: loan treasurer does not match expected address"
        );

        assertTrue(
            loanManagerAccessControllerHarness.hasRole(
                _TREASURER_,
                _loanTreasurerAddress
            ),
            "5 :: loan treasurer should have treasurer role"
        );

        // Change with admin
        loanManagerAccessControllerHarness.grantRole(
            _TREASURER_,
            _alt_loanTreasurerAddress
        );

        assertEq(
            loanManagerAccessControllerHarness.loanTreasurer(),
            _alt_loanTreasurerAddress,
            "6 :: alt loan treasurer does not match expected address"
        );

        assertTrue(
            loanManagerAccessControllerHarness.hasRole(
                _TREASURER_,
                _alt_loanTreasurerAddress
            ),
            "7 :: alt loan treasurer should have treasurer role"
        );

        assertFalse(
            loanManagerAccessControllerHarness.hasRole(
                _TREASURER_,
                _loanTreasurerAddress
            ),
            "8 :: loan treasurer should not have treasurer role"
        );
        vm.stopPrank();
    }
}
