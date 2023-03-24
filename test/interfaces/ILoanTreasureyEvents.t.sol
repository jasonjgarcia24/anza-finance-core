// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILoanTreasureyEvents {
    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
}
