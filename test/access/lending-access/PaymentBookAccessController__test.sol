// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {PaymentBookAccessController} from "@lending-access/PaymentBookAccessController.sol";

import {Setup} from "@test-base/Setup__test.sol";

contract PaymentBookAccessContollerHarness is PaymentBookAccessController {
    function exposed__setAnzaToken(address _anzaTokenAddress) public {
        _setAnzaToken(_anzaTokenAddress);
    }

    /* Abstract functions */
    function setAnzaToken(address _anzaTokenAddress) public virtual override {}
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract PaymentBookAccessControllerInit is Setup {
    PaymentBookAccessContollerHarness public paymentBookAccessControllerHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        paymentBookAccessControllerHarness = new PaymentBookAccessContollerHarness();
        vm.stopPrank();
    }
}

contract PaymentBookAccessControllerUnitTest is
    PaymentBookAccessControllerInit
{
    /* ----------- PaymentBookAccessController._setAnzaToken() ----------- */
    /**
     * Fuzz test for setting the anza token address.
     *
     * @param _anzaTokenAddress The address of the AnzaToken contract.
     *
     * @dev Full pass if the address is set correctly.
     * @dev Caught fail/pass if the function reverts with the expected error.
     */
    function testPaymentBookAccessController__Fuzz_SetAnzaToken(
        address _anzaTokenAddress
    ) public {
        assertEq(
            address(paymentBookAccessControllerHarness.anzaToken()),
            address(0),
            "0 :: anzaToken should be address(0)."
        );

        paymentBookAccessControllerHarness.exposed__setAnzaToken(
            _anzaTokenAddress
        );

        assertEq(
            address(paymentBookAccessControllerHarness.anzaToken()),
            _anzaTokenAddress,
            "1 :: anzaToken does not match expected address"
        );
    }
}
