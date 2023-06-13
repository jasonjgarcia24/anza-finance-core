// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface ICollateralVault {
    error UnallowedDeposit();
    error UnallowedWithdrawal();
    error IllegalDebtId();

    event DepositedCollateral(
        address indexed from,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    event WithdrawnCollateral(
        address indexed to,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    struct Collateral {
        address collateralAddress;
        uint256 collateralId;
        uint256 activeLoanIndex;
    }

    function totalCollateral() external view returns (uint256);

    function getCollateral(
        uint256 _debtId
    ) external view returns (Collateral memory);

    function setCollateral(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) external;

    function depositAllowed(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) external returns (bool);

    function withdrawalAllowed(
        address _to,
        uint256 _debtId
    ) external view returns (bool);

    function withdraw(
        address _loanContractAddress,
        uint256 _debtId
    ) external returns (bool);
}
