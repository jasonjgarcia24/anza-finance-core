// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPaymentBook {
    event Deposited(
        uint256 indexed debtId,
        address indexed payer,
        address indexed payee,
        uint256 weiAmount
    );

    event Withdrawn(address indexed payee, uint256 weiAmount);

    function depositFunds(address _payee) external payable;

    function depositFunds(
        uint256 _debtId,
        address _payer,
        address _payee
    ) external payable;

    function withdrawableBalance(
        address _account
    ) external view returns (uint256);
}
