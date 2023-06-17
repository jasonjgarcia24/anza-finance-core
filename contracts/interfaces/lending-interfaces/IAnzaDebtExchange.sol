// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaDebtExchange {
    function executeDebtPurchase(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _purchaser
    ) external payable returns (bool _results);

    function executeDebtTransfer(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _beneficiary
    ) external returns (bool _results);

    function executeRefinancePurchase(
        uint256 _debtId,
        address _borrower,
        address _purchaser,
        bytes32 _contracTerms
    ) external payable returns (bool _results);

    function executeSponsorshipPurchase(
        uint256 _debtId,
        address _purchaser
    ) external payable returns (bool _results);
}
