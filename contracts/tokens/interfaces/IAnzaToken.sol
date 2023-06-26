// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaToken {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function debtId(uint256 _tokenId) external pure returns (uint256);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

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

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// - MUST revert on any other error.
    /// - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// - After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _debtId ID of the token type
    /// @param _amount Transfer amount
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /// @notice Send multiple types of Tokens from the `_from` address to the `_to` address (with safety call).
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _debtIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    /// @param _debtId argument MUST be the debt ID for deriving token ID being transferred.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    function mint(uint256 _debtId, uint256 _amount) external;

    /// @param _to argument MUST be the address of the recipient whose balance is increased.
    /// @param _debtId argument MUST be the debt ID for deriving token ID being transferred.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function mint(
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes memory _data
    ) external;

    /// @param _to argument MUST be the address of the recipient whose balance is increased.
    /// @param _id argument MUST be the token ID being transferred.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string calldata _collateralURI,
        bytes memory _data
    ) external;

    /// @param _account argument MUST be the address of the owner/operator whose balance is decreased.
    /// @param _id argument MUST be the token being burned.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by.
    function burn(address _account, uint256 _id, uint256 _amount) external;

    /// @param _address argument MUST be the address of the owner/operator whose balance is decreased.
    /// @param _ids argument MUST be the tokens being burned.
    /// @param _amounts argument MUST be the number of tokens the holder balance is decreased by.
    function burnBatch(
        address _address,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    /// @param _debtId argument MUST be the debt ID for deriving token ID being burned.
    function burnBorrowerToken(uint256 _debtId) external;

    /// @param _debtId argument MUST be the debt ID for deriving token ID being burned.
    /// @param _debtId argument MUST be the debt ID for deriving token ID being burned.
    function burnLenderToken(uint256 _debtId, uint256 _amount) external;
}
