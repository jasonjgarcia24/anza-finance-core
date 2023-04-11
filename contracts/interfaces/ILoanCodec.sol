// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoanCodec {
    error InactiveLoanState();
    error InvalidLoanParameter(bytes4 parameter);

    function getDebtTerms(uint256 _debtId) external view returns (bytes32);

    function loanState(uint256 _debtId) external view returns (uint256);

    function firInterval(uint256 _debtId) external view returns (uint256);

    function fixedInterestRate(uint256 _debtId) external view returns (uint256);

    function loanLastChecked(uint256 _debtId) external view returns (uint256);

    function loanStart(uint256 _debtId) external view returns (uint256);

    function loanClose(uint256 _debtId) external view returns (uint256);

    function lenderRoyalties(uint256 _debtId) external view returns (uint256);

    function activeLoanCount(uint256 _debtId) external view returns (uint256);

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) external view returns (uint256);
}
