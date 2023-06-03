// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";

import "../domain/AnzaTokenTransferTypes.sol";

import "../access/AnzaTokenAccessController.sol";
import "./AnzaTokenURIStorage.sol";
import "../interfaces/IAnzaBase.sol";
import "../interfaces/IAnzaTokenLite.sol";

abstract contract AnzaBaseToken is
    IAnzaTokenLite,
    AnzaTokenAccessController,
    AnzaTokenURIStorage
{
    string private __name;
    string private __symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC1155(_baseURI) {
        __name = _name;
        __symbol = _symbol;
    }

    function name() external view returns (string memory) {
        return __name;
    }

    function symbol() external view returns (string memory) {
        return __symbol;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return
            _interfaceId == type(IAnzaTokenLite).interfaceId ||
            ERC1155.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }
}
