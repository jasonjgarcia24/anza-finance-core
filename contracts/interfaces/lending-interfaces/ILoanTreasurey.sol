// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanTreasurey {
    event Deposited(
        uint256 indexed debtId,
        address indexed payer,
        uint256 weiAmount
    );

    event Withdrawn(address indexed payee, uint256 weiAmount);

    function sponsorPayment(address _sponsor, uint256 _debtId) external payable;

    function depositPayment(uint256 _debtId) external payable;

    function withdrawFromBalance(uint256 _amount) external returns (bool);

    function withdrawCollateral(uint256 _debtId) external returns (bool);

    function executeDebtPurchase(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _purchaser
    ) external payable returns (bool);

    function updateDebt(uint256 _debtId) external returns (bool);
}
