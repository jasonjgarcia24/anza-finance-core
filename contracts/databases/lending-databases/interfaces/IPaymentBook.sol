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

    function withdrawableBalance(
        address _account
    ) external view returns (uint256);
}
