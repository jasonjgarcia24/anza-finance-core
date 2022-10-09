// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AnzaDeptToken is ERC1155URIStorage, Pausable {

    constructor(string memory _uri) ERC1155(_uri) {
        _pause();
    }

    function name() external pure returns (string memory) {
        return 'AnzaDebtToken';
    }

    function symbol() external pure returns (string memory) {
        return 'ADT';
    }

    /**
     * @dev Contract module which allows children to implement an emergency stop
     * mechanism that can be triggered by an authorized account.
     *
     * This module is used through inheritance. It will make available the
     * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
     * the functions of your contract. Note that they will not be pausable by
     * simply including this module, only once the modifiers are put in place.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }}
