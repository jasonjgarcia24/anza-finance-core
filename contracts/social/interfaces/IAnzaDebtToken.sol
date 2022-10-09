// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAnzaDebtToken {
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
}
