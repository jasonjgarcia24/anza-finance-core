// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILoanTreasurey {
    function setDebtTokenAddress(address _debtTokenAddress) external;

    function makePayment(address _loanContract) external payable;

    function getDebtTokenAddress() external returns (address);

    function issueDebtToken(string memory _debtURI) external;

    function getBalance(address _loanContractAddress) external view returns (uint256);

    function assessMaturity(address _loanContractAddress) external;
}