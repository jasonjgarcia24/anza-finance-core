// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { LibContractGlobals as Globals } from "./LibContractMaster.sol";
import { StateControlUint } from "../../utils/StateControl.sol";

import "hardhat/console.sol";

library LibContractScheduler {
    using StateControlUint for StateControlUint.Property;

    function initSchedule_(
        Globals.Property storage _properties, Globals.Global storage _globals
    ) public {
        uint256 _blockNumber = block.number + _properties.duration.get();
        _properties.stopBlockstamp.set(_blockNumber, _globals.state);
    }
}
