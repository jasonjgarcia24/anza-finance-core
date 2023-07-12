// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";

library StringUtils {
    using Strings for uint256;

    function concatTestStr(
        string memory _str,
        uint256 _pos,
        uint256 _num
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _pos.toString(),
                    " :: ",
                    _str,
                    " ",
                    _num.toString(),
                    "."
                )
            );
    }
}
