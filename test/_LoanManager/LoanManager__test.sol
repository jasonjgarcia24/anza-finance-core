// SPDX-License-Identifier: UNLICESNED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {LoanTreasurey} from "@base/LoanTreasurey.sol";

import {Utils} from "@test-base/Setup__test.sol";

abstract contract LoanManagerDeployer is Utils {
    LoanTreasurey public loanTreasurer;
}
