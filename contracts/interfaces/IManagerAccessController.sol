// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAnzaToken} from "./IAnzaToken.sol";
import {ILoanTreasurey} from "./ILoanTreasurey.sol";
import {ICollateralVault} from "./ICollateralVault.sol";

interface IManagerAccessController {
    function anzaToken() external returns (address);

    function loanTreasurer() external returns (address);

    function collateralVault() external returns (address);

    function setAnzaToken(address _anzaTokenAddress) external;

    function setLoanTreasurer(address _loanTreasurerAddress) external;

    function setCollateralVault(address _collateralVaultAddress) external;
}
