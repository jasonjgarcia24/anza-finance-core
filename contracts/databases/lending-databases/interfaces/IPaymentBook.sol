// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPaymentBook {
    event Deposited(
        uint256 indexed debtId,
        address indexed payer,
        address payee,
        uint256 weiAmount
    );

    event DebtExchanged(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        address indexed payer,
        address payee,
        uint256 weiAmount
    );

    event Withdrawn(address indexed payee, uint256 weiAmount);

    function depositFunds(address _payee) external payable returns (bool);

    function depositFunds(
        uint256 _debtId,
        address _payer,
        address _payee
    ) external payable returns (bool);

    function withdrawableBalance(
        address _account
    ) external view returns (uint256);
}
