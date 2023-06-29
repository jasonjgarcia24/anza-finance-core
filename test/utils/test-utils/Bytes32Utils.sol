// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

library Bytes32Utils {
    function addressFromLast20Bytes(
        bytes32 bytesValue
    ) public pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }
}
