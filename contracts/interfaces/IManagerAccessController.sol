// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IManagerAccessController {
    function anzaToken() external returns (address);

    function loanTreasurer() external returns (address);

    function collateralVault() external returns (address);

    function setAnzaToken(address _anzaTokenAddress) external;

    function setLoanTreasurer(address _loanTreasurerAddress) external;

    function setCollateralVault(address _collateralVaultAddress) external;
}
