// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILoanTreasurey {
    error InvalidParticipant(address account);
    error InsufficientFunds(uint256 amount);
    error InactiveLoanState(uint256 debtId);

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    function sponsorPayment(uint256 _debtId) external payable;

    function depositPayment(uint256 _debtId) external payable;

    function withdrawPayment(uint256 _amount) external returns (bool);

    function withdrawCollateral(uint256 _debtId) external returns (bool);

    function setBalanceWithInterest(uint256 _debtId) external returns (uint256);
}
