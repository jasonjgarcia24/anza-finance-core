// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanNotaryErrors {
    error InvalidParticipant();
    error InvalidSignatureLength();
}

interface ILoanNotary is ILoanNotaryErrors {
    struct ContractParams {
        uint256 principal;
        bytes32 contractTerms;
        address collateralAddress;
        uint256 collateralId;
        uint256 collateralNonce;
    }
}

interface IListingNotary is ILoanNotaryErrors {
    struct ListingParams {
        uint256 price;
        uint256 debtId;
        uint256 listingNonce;
        uint256 termsExpiry;
    }
}
