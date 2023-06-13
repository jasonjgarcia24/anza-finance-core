// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IDebtBookAccessController {
    function anzaToken() external returns (address);

    function collateralVault() external returns (address);
}
