// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaTokenIndexer {
    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    function ownerOf(uint256 _tokenId) external view returns (address);

    // function balanceOf(
    //     address account,
    //     uint256 id
    // ) external view returns (uint256);

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
}
