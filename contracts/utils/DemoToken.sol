// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DemoToken is ERC721 {
    uint256 public totalSupply;

    string public baseURI = "https://www.demo_token_metadata_uri.com/";

    mapping(address => uint256[]) public ownedTokens;

    constructor() ERC721("Demo Token", "DT") {
        while (totalSupply < 50) {
            _safeMint(msg.sender, ++totalSupply);
        }
    }

    function getOwnedTokens(
        address _owner
    ) external view returns (uint256[] memory) {
        return ownedTokens[_owner];
    }

    function getOwnedTokenCount(
        address _owner
    ) external view returns (uint256) {
        return ownedTokens[_owner].length;
    }

    function mint(uint256 _amount) public {
        uint256 _updatedSupply = totalSupply + _amount;

        while (totalSupply < _updatedSupply) {
            _safeMint(msg.sender, ++totalSupply);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        if (_from != address(0)) {
            uint256[] storage _ownedTokens = ownedTokens[_from];
            uint256 _idx = _ownedTokens.length;

            for (uint256 i = 0; i < _ownedTokens.length; i++) {
                if (_ownedTokens[i] == _tokenId) {
                    _idx = i;
                    break;
                }
            }

            for (uint256 i = _idx; i < _ownedTokens.length - 1; i++) {
                _ownedTokens[i] = _ownedTokens[i + 1];
            }
            _ownedTokens.pop();
        }

        ownedTokens[_to].push(_tokenId);

        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
}
