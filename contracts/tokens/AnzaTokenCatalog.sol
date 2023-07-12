// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {IAnzaTokenCatalog} from "@tokens-interfaces/IAnzaTokenCatalog.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

abstract contract AnzaTokenCatalog is IAnzaTokenCatalog {
    using AnzaTokenIndexer for uint256;

    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    // Mapping from token ID to owner address
    mapping(uint256 => address) private __owners;
    mapping(uint256 => uint256) internal __totalSupply;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IAnzaTokenCatalog).interfaceId;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return __owners[_tokenId];
    }

    function borrowerOf(uint256 _debtId) public view returns (address) {
        return __owners[_debtId.debtIdToBorrowerTokenId()];
    }

    function lenderOf(uint256 _debtId) public view returns (address) {
        return __owners[_debtId.debtIdToLenderTokenId()];
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view returns (uint256) {
        return __totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view returns (bool) {
        unchecked {
            return totalSupply(id) > 0;
        }
    }

    function _setOwner(uint256 _tokenId, address _owner) internal {
        __owners[_tokenId] = _owner;
    }

    function _setTotalSupply(uint256 _tokenId, uint256 _amount) internal {
        __totalSupply[_tokenId] = _amount;
    }

    function _incrementTotalSupply(uint256 _tokenId, uint256 _amount) internal {
        __totalSupply[_tokenId] += _amount;
    }

    function _decrementTotalSupply(uint256 _tokenId, uint256 _amount) internal {
        __totalSupply[_tokenId] -= _amount;
    }
}
