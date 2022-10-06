// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract DemoToken is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    event Mint(address indexed owner, address indexed tokenContract, uint256 indexed tokenId);

    constructor () ERC721("Demo", "DT") {}

    function mint(address _to) public {
        tokenIds.increment();
        _safeMint(_to, tokenIds.current());

        emit Mint(_to, address(this), tokenIds.current());
    }

    function getTokenId() public view returns (uint256) {
        return tokenIds.current();
    }
}