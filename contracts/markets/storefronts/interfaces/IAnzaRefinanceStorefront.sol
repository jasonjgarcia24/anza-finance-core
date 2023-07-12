// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaRefinanceStorefront {
    function buyRefinance(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes32 _contractTerms,
        bytes calldata _sellerSignature
    ) external payable;

    function buyRefinance(
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes32 _contractTerms,
        bytes calldata _sellerSignature
    ) external payable;
}
