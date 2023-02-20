// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ILoanContract is IERC721Enumerable, IAccessControl {
    event TokenInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId
    );

    function totalDebtSupply() external view returns (uint256);
}
