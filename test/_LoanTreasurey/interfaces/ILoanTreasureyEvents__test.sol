// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanTreasureyEvents {
    event Deposited(
        uint256 indexed debtId,
        address indexed payer,
        uint256 weiAmount
    );

    event Withdrawn(address indexed payee, uint256 weiAmount);
}
