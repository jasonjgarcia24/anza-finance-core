// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaBaseMarketParticipant {
    enum ListingType {
        UNDEFINED,
        DEBT,
        REFINANCE,
        CONSOLIDATION,
        SPONSORSHIP,
        OTHER_APPROVED
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
        uint8 indexed listingType,
        address indexed contractAddress,
        uint256 assetId
    );

    function nonce() external view returns (uint256);
}
