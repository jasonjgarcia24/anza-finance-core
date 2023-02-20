// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DemoToken is ERC721 {
    uint256 public totalSupply;

    constructor() ERC721("Demo Token", "DT") {
        while (totalSupply < 50) {
            _safeMint(msg.sender, totalSupply);
            totalSupply++;
        }
    }
}
