// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAccountantAccessController {
    function loanContract() external view returns (address);

    function collateralVault() external view returns (address);

    function setLoanContract(address _loanContractAddress) external;

    function setCollateralVault(address _collateralVaultAddress) external;
}
