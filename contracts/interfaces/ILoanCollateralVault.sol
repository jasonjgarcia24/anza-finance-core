// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

interface ILoanCollateralVault {
    error InvalidParticipant(address account);
    error InvalidDepositMsg(
        address expectedTokenAddress,
        address actualTokenAddress
    );

    event CollateralDeposited(
        address indexed from,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    event CollateralWithdrawn(
        address indexed to,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    struct Collateral {
        address collateralAddress;
        uint256 collateralId;
    }

    function totalCollateral() external view returns (uint256);

    function getCollateralAt(
        uint256 _debtId
    ) external view returns (Collateral memory);

    function withdraw(address _to, uint256 _debtId) external returns (bool);
}
