// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAnzaDebtToken is IERC1155 {
    /**
     * @dev Get token name.
     */
    function name() external pure returns (string memory);

    /**
     * @dev Get token symbol.
     */
    function symbol() external pure returns (string memory);

    /**
     * @dev Mint token for the `debtId` (i.e. tokenId).
     * 
     * Requirements:
     * 
     * - Must be paused.
     */
    function mintDebt(
        address _to,
        uint256 _debtId,
        uint256 _amount,
        string memory _debtURI
    ) external;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) external view returns (string memory);
}