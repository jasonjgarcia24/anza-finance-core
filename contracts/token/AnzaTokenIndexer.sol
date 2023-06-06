// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../../lib/forge-std/src/console.sol";

import {IAnzaTokenIndexer} from "../interfaces/IAnzaTokenIndexer.sol";

abstract contract AnzaTokenIndexer is IAnzaTokenIndexer {
    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    // Mapping from token ID to owner address
    mapping(uint256 => address) private __owners;
    mapping(uint256 => uint256) internal __totalSupply;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IAnzaTokenIndexer).interfaceId;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return __owners[_tokenId];
    }

    function debtId(uint256 _tokenId) public pure returns (uint256) {
        return _tokenId / 2;
    }

    function borrowerOf(uint256 _debtId) public view returns (address) {
        return __owners[borrowerTokenId(_debtId)];
    }

    function lenderOf(uint256 _debtId) public view returns (address) {
        return __owners[lenderTokenId(_debtId)];
    }

    function borrowerTokenId(uint256 _debtId) public pure returns (uint256) {
        return (_debtId * 2) + 1;
    }

    function lenderTokenId(uint256 _debtId) public pure returns (uint256) {
        return _debtId * 2;
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
        return totalSupply(id) > 0;
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
