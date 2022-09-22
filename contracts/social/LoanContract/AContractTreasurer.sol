// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractAffirm.sol";

abstract contract AContractTreasurer is AContractAffirm {
    mapping(address => uint256) internal accountBalance;
    
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

    receive() external payable {}
}