// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaDebtStorefront {
    error InvalidListingType();
    error CanceledListing();
    error LockedNonce();

    enum ListingType {
        UNDEFINED,
        DEBT,
        REFINANCE,
        SPONSORSHIP
    }

    struct Nonce {
        ListingType listingType;
        address publisher;
        bool locked;
    }

    event DebtListed(
        address indexed seller,
        uint256 indexed debtId,
        uint256 indexed price
    );

    event ListingRegistered(
        address indexed seller,
        uint256 indexed debtId,
        uint8 indexed listingType,
        uint256 nonce
    );

    event ListingCancelled(address indexed seller, uint256 indexed debtId);

    event ListingPurchased(
        address indexed buyer,
        uint256 indexed debtId,
        uint8 indexed listingType,
        uint256 price
    );

    function buyDebt(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;

    function buySponsorship(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;
}
