// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_INVALID_ADDRESS_ERROR_ID_} from "@custom-errors/StdAccessErrors.sol";

import {DebtBookAccessController} from "@lending-access/DebtBookAccessController.sol";

import {Setup} from "@test-base/Setup__test.sol";

contract DebtBookAccessContollerHarness is DebtBookAccessController {
    function exposed__setAnzaToken(address _anzaTokenAddress) public {
        _setAnzaToken(_anzaTokenAddress);
    }

    function exposed__setCollateralVault(
        address _collateralVaultAddress
    ) public {
        _setCollateralVault(_collateralVaultAddress);
    }

    /* Abstract functions */
    function setAnzaToken(address _anzaTokenAddress) public virtual override {}

    function setCollateralVault(
        address _collateralVaultAddress
    ) public virtual override {}
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract DebtBookAccessControllerInit is Setup {
    DebtBookAccessContollerHarness public debtBookAccessControllerHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        debtBookAccessControllerHarness = new DebtBookAccessContollerHarness();
        vm.stopPrank();
    }
}

contract DebtBookAccessControllerUnitTest is DebtBookAccessControllerInit {
    /* ----------- DebtBookAccessController._setAnzaToken() ----------- */
    /**
     * Fuzz test for setting the anza token address.
     *
     * @param _anzaTokenAddress The address of the AnzaToken contract.
     *
     * @dev Full pass if the address is set correctly.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testDebtBookAccessController__Fuzz_SetAnzaToken(
        address _anzaTokenAddress
    ) public {
        assertEq(
            address(debtBookAccessControllerHarness.anzaToken()),
            address(0),
            "0 :: anzaToken should be address(0)."
        );

        try
            debtBookAccessControllerHarness.exposed__setAnzaToken(
                _anzaTokenAddress
            )
        {
            assertEq(
                address(debtBookAccessControllerHarness.anzaToken()),
                _anzaTokenAddress,
                "1 :: anzaToken does not match expected address"
            );
        } catch (bytes memory _err) {
            if (_anzaTokenAddress == address(0)) {
                assertEq(
                    bytes4(_err),
                    _INVALID_ADDRESS_ERROR_ID_,
                    "2 :: 'invalid address failure' expected."
                );
            }
        }
    }

    /* -------- DebtBookAccessController._setCollateralVault() -------- */
    /**
     * Fuzz test for setting the anza token address.
     *
     * @param _collateralVault The address of the CollateralVault contract.
     *
     * @dev Full pass if the address is set correctly.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testDebtBookAccessController__Fuzz_SetCollateralVault(
        address _collateralVault
    ) public {
        assertEq(
            debtBookAccessControllerHarness.collateralVault(),
            address(0),
            "0 :: collateral vault should be address(0)."
        );

        try
            debtBookAccessControllerHarness.exposed__setCollateralVault(
                _collateralVault
            )
        {
            assertEq(
                debtBookAccessControllerHarness.collateralVault(),
                _collateralVault,
                "1 :: collateral vault does not match expected address."
            );
        } catch (bytes memory _err) {
            if (_collateralVault == address(0)) {
                assertEq(
                    bytes4(_err),
                    _INVALID_ADDRESS_ERROR_ID_,
                    "2 :: 'invalid address failure' expected."
                );
            }
        }
    }
}
