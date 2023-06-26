// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanCodec {
    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) external view returns (uint256);
}
