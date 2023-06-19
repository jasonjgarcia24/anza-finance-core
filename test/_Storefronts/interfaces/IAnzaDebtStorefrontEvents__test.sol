// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAnzaDebtStorefrontEvents {
    error InvalidDebtOwner(address debtOwner);
    error InvalidListingTerms();
    error InsufficientPayment(uint256 payment);
    error InsufficientProceeds(address payee);
    error ExistingListing(uint256 debtId);
    error NonExistingListing(uint256 debtId);
    error NotApprovedForMarketplace();

    event DebtListed(
        address indexed seller,
        uint256 indexed debtId,
        uint256 indexed price
    );

    event ListingCancelled(address indexed seller, uint256 indexed debtId);

    event DebtPurchased(
        address indexed buyer,
        uint256 indexed debtId,
        uint256 price
    );

    struct Listing {
        uint256 price;
        address debtOwner;
        address collateralAddress;
        uint256 collateralId;
        bytes32 debtTerms;
    }
}
