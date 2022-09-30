// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { LibContractGlobals as cg } from "./LibContractMaster.sol";
import { StateControlUint } from "../../utils/StateControl.sol";

library LibContractScheduler {
    using StateControlUint for StateControlUint.Property;

    function _initSchedule(
        cg.Property storage _properties, cg.Global storage _globals
    ) internal {
        uint256 _blockNumber = block.number + _properties.duration.get();
        _properties.stopBlockstamp.set(_blockNumber, uint256(_globals.state));
    }
}
