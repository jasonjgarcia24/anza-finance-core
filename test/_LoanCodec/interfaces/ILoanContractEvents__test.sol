// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanCodecEvents {
    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );
}
