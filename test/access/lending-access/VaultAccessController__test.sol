// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_INVALID_ADDRESS_ERROR_ID_} from "@custom-errors/StdAccessErrors.sol";
import "@lending-constants/LoanContractRoles.sol";

import {VaultAccessController} from "@lending-access/VaultAccessController.sol";
import {AnzaToken} from "@tokens/AnzaToken.sol";

import {Setup} from "@test-base/Setup__test.sol";

contract VaultAccessControllerHarness is VaultAccessController {
    constructor(
        address _anzaTokenAddress
    ) VaultAccessController(_anzaTokenAddress) {}

    /* Abstract functions */
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract VaultAccessControllerInit is Setup {
    VaultAccessControllerHarness public vaultAccessControllerHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        // Deploy AnzaToken
        anzaToken = new AnzaToken("www.anza.io");

        vaultAccessControllerHarness = new VaultAccessControllerHarness(
            address(anzaToken)
        );
        vm.stopPrank();
    }
}

contract VaultAccessControllerUnitTest is VaultAccessControllerInit {
    /* ------------ VaultAccessController.anzaToken() ------------ */
    /**
     * Fuzz test anza token address.
     *
     * @dev Full pass if the address is set correctly.
     */
    function testVaultAccessController__Fuzz_AnzaToken(
        address _anzaTokenAddress
    ) public {
        VaultAccessControllerHarness _vaultAccessController = new VaultAccessControllerHarness(
                _anzaTokenAddress
            );

        assertEq(
            _vaultAccessController.anzaToken(),
            _anzaTokenAddress,
            "0 :: anzaToken does not match expected address."
        );
    }

    /* --------- VaultAccessController.setLoanContract() --------- */
    /**
     * Fuzz test for checking the LoanContract.
     *
     * @param _loanContract The address of the LoanContract.
     *
     * @dev Full pass if the address is set correctly.
     */
    function testVaultAccessController__Fuzz_SetLoanContract(
        address _loanContract
    ) public {
        assertFalse(
            vaultAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _loanContract
            ),
            "0 :: loanContract should be address(0)."
        );

        assertEq(
            vaultAccessControllerHarness.loanContract(),
            address(0),
            "1 :: loanContract should be address(0)."
        );

        vm.expectRevert(
            abi.encodePacked(getAccessControlFailMsg(_ADMIN_, address(this)))
        );
        vaultAccessControllerHarness.setLoanContract(_loanContract);

        vm.startPrank(admin);
        vaultAccessControllerHarness.setLoanContract(_loanContract);
        vm.stopPrank();

        assertTrue(
            vaultAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _loanContract
            ),
            "2 :: loanContract does not match expected address."
        );

        assertEq(
            vaultAccessControllerHarness.loanContract(),
            _loanContract,
            "3 :: loanContract does not match expected address."
        );
    }
}
