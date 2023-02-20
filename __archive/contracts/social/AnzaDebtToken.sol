// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

import "./interfaces/IAnzaDebtToken.sol";
import { LibContractGlobals as Globals } from "./libraries/LibContractMaster.sol";

contract AnzaDebtToken is ERC1155URIStorage, AccessControl {

    // timestamp when token release is enabled
    uint256 private immutable releaseBlock;

    constructor(
        string memory _baseURI,
        address _admin,
        address _treasurer,
        uint256 _releaseBlock
    )
        ERC1155(_baseURI)
    {
        _setBaseURI(_baseURI);

        _setupRole(Globals._ADMIN_ROLE_, _admin);
        _setRoleAdmin(Globals._TREASURER_ROLE_, Globals._ADMIN_ROLE_);

        _setupRole(Globals._TREASURER_ROLE_, _treasurer);

        releaseBlock = _releaseBlock;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return interfaceId == type(IAnzaDebtToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get token name.
     */
    function name() external pure returns (string memory) {
        return 'AnzaDebtToken';
    }

    /**
     * @dev Get token symbol.
     */
    function symbol() external pure returns (string memory) {
        return 'ADT';
    }

    /**
     * @dev Mint token for the `debtId` (i.e. tokenId).
     * 
     * Requirements:
     * 
     * - The `releaseBlock` must be at least `block.number`.
     */
    function mintDebt(
        address _to,
        uint256 _debtId,
        uint256 _amount,
        string calldata _debtURI
    ) external onlyRole(Globals._TREASURER_ROLE_) {
        require(releaseBlock <= block.number, "ADT minting timelocked.");

        _mint(_to, _debtId, _amount, "");
        _setURI(_debtId, _debtURI);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of batched `ids`.
     */
    function _setBatchURI(uint256[] memory ids, string memory tokenURI) internal {
        for (uint i; i < ids.length; i++) {
            _setURI(ids[i], tokenURI);
        }
    }

    /**
     * @notice Source: OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)
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
    }
}
