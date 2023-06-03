// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaBase {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);
}
