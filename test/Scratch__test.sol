// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract Scratch {
    function thing1() external pure returns (uint256) {
        return addmod(type(uint256).max, type(uint256).max, 201324);
    }

    function thing2() external pure returns (uint256) {
        return (1 + 2) % 3;
    }

    function thing3() external pure returns (uint256) {
        return mulmod(type(uint256).max, type(uint256).max, 201324);
    }

    function thing4() external pure returns (uint256) {
        return (1 * 2) % 3;
    }
}

contract ScratchTest is Test {
    Scratch demo = new Scratch();

    function testDemo() public view {
        console.log(demo.thing1());
        console.log(demo.thing2());
        console.log(demo.thing3());
        console.log(demo.thing4());
    }
}
