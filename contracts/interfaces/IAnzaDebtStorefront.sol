// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaDebtStorefront {
    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _termsExpiry,
        bytes calldata _borrowerSignature
    ) external payable;

    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes calldata _borrowerSignature
    ) external payable;
}
