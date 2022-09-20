// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IContract.sol";

abstract contract AContractAffirm is IContract {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}