// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface ILoanCollateralVaultEvents {
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
}
