// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@token-constants/AnzaTokenTransferTypes.sol";

import {IAnzaBase} from "@token-interfaces/IAnzaBase.sol";
import {AnzaTokenAccessController} from "@token-access/AnzaTokenAccessController.sol";
import {AnzaTokenURIStorage, ERC1155} from "./AnzaTokenURIStorage.sol";

abstract contract AnzaBaseToken is
    IAnzaBase,
    AnzaTokenAccessController,
    AnzaTokenURIStorage
{
    string private __name;
    string private __symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC1155(_baseURI) AnzaTokenAccessController() {
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
    ) public view virtual override(AnzaTokenAccessController, ERC1155) returns (bool) {
        return
            _interfaceId == type(IAnzaBase).interfaceId ||
            ERC1155.supportsInterface(_interfaceId) ||
            AnzaTokenAccessController.supportsInterface(_interfaceId);
    }
}
