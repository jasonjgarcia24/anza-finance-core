// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library BlockTime {
    function daysToBlocks(uint256 _days) public pure returns (uint256) {
        // days => hr => min => blk
        return _days * 24 * 60 * 5;
    }

    function blocksToDays(uint256 _block) public pure returns (uint256) {
        // blk => min => hr => blk
        return _block / 5 / 60 / 24;
    }
}
