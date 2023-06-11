// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaSponsorshipStorefront {
    function buySponsorship(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;

    function buySponsorship(
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;
}
