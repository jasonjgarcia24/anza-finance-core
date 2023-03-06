// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILoanContractEvents {
    event LoanContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId
    );
}
