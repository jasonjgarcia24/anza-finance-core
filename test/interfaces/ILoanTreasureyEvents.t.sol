// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanTreasureyEvents {
    error InvalidParticipant();
    error InvalidFundsTransfer();
    error InactiveLoanState();
    error InvalidLoanState();

    event Deposited(
        uint256 indexed debtId,
        address indexed payer,
        uint256 weiAmount
    );

    event Withdrawn(address indexed payee, uint256 weiAmount);
}
