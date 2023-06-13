// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IManagerAccessController {
    function loanTreasurer() external returns (address);

    function setLoanTreasurer(address _loanTreasurerAddress) external;
}
