// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaDebtStorefront {
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

    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;

    function buyDebt(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;

    function buySponsorship(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;

    function buySponsorship(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable;
}
