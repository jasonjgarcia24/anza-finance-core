// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IAnzaToken {
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

    /// @notice Get the borrower token ID for a given debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The borrower token ID of the debt.
    function borrowerTokenId(uint256 _debtId) external pure returns (uint256);

    /// @notice Get the lender token ID for a given debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The lender token ID of the debt.
    function lenderTokenId(uint256 _debtId) external pure returns (uint256);

    /// @dev Total amount of tokens in with a given id.
    function totalSupply(uint256 id) external view returns (uint256);

    /// @param _to argument MUST be the address of the recipient whose balance is increased.
    /// @param _id argument MUST be the token ID being transferred.
    /// @param _value argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function mint(
        address _to,
        uint256 _id,
        uint256 _value,
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
