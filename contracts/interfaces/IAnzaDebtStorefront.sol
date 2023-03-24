// SPDX-License-Identifer: MIT
pragma solidity ^0.8.7;

interface IAnzaDebtStorefront {
    error InvalidDebtOwner(address debtOwner);
    error InvalidListingPrice(uint256 price);
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

    function listDebt(uint256 _debtId, uint256 _price) external;

    function cancelListing(uint256 _debtId) external;

    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) external payable;

    function buyDebt(uint256 _debtId) external payable;

    function updateListing(uint256 _debtId, uint256 _newPrice) external;

    function withdrawProceeds() external;

    function getListing(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (Listing memory);

    function getListing(uint256 _debtId) external view returns (Listing memory);

    function getProceeds(address _seller) external view returns (uint256);
}
