// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractGlobals.sol";

abstract contract AContractScheduler is AContractGlobals {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;

    function _initSchedule() internal {
        uint256 _blockNumber = block.number + duration.get();
        stopBlockstamp.set(_blockNumber, uint16(state));
    }
}
