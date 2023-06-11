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

interface IDebtNotary is ILoanNotaryErrors {
    struct DebtParams {
        uint256 price;
        address collateralAddress;
        uint256 collateralId;
        uint256 listingNonce;
        uint256 termsExpiry;
    }
}

interface ISponsorshipNotary is ILoanNotaryErrors {
    struct SponsorshipParams {
        uint256 price;
        uint256 debtId;
        uint256 listingNonce;
        uint256 termsExpiry;
    }
}

interface IRefinanceNotary is ILoanNotaryErrors {
    struct RefinanceParams {
        uint256 price;
        uint256 debtId;
        uint256 listingNonce;
        uint256 termsExpiry;
        bytes32 contractTerms;
    }
}
