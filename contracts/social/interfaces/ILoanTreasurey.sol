// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILoanTreasurey {
    function setDebtTokenAddress(address _debtTokenAddress) external;

    function getDebtTokenAddress() external returns (address);

    function issueDebtToken(string memory _debtURI) external;

    function updateBalance(address _loanContractAddress) external;

    function assessMaturity(address _loanContractAddress) external;
}