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

    function listDebt(
        uint256 _debtId,
        uint256 _price,
        bytes32 _debtTerms
    ) external;

    function cancelListing(uint256 _debtId) external;

    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) external;

    function buyDebt(uint256 _debtId) external;

    function updateListing(uint256 _debtId, uint256 _newPrice) external;

    function withdrawProceeds() external;

    function getListing(
        address _collateralAddress,
        uint256 _collateralId
    ) external;
}
