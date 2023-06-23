// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ICollateralVaultEvents {
    event DepositedCollateral(
        address indexed from,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    event WithdrawnCollateral(
        address indexed to,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );
}