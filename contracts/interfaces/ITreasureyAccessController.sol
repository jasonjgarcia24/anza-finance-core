// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasureyAccessController {
    function anzaToken() external view returns (address);

    function loanContract() external view returns (address);

    function collateralVault() external view returns (address);

    function setAnzaToken(address _anzaTokenAddress) external;

    function setLoanContract(address _loanContractAddress) external;

    function setCollateralVault(address _collateralVaultAddress) external;
}
