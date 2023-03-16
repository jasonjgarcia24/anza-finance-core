// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAnzaERC1155.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IAnzaToken is IAnzaERC1155 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Get the borrower of a debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The borrower of the debt.
    function borrowerOf(uint256 _debtId) external view returns (address);

    /// @notice Get the lender of a debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The lender of the debt.
    function lenderOf(uint256 _debtId) external view returns (address);

    /// @param _to argument MUST be the list of addresses of the recipient whose balance is increased.
    /// @param _ids argument MUST be the list of tokens being transferred.
    /// @param _values argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function mint(
        address[2] memory _to,
        uint256[2] memory _ids,
        uint256[2] memory _values,
        string calldata _collateralURI,
        bytes memory _data
    ) external;

    /// @param _account argument MUST be the address of the owner/operator whose balance is decreased.
    /// @param _id argument MUST be the token being burned.
    /// @param _value argument MUST be the number of tokens the holder balance is decreased by.
    function burn(address _account, uint256 _id, uint256 _value) external;

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _values
    ) external;
}
