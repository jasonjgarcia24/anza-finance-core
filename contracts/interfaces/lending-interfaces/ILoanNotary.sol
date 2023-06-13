// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanNotary {
    struct ContractParams {
        uint256 principal;
        bytes32 contractTerms;
        address collateralAddress;
        uint256 collateralId;
        uint256 collateralNonce;
    }
}

interface IDebtNotary {
    struct DebtParams {
        uint256 price;
        address collateralAddress;
        uint256 collateralId;
        uint256 listingNonce;
        uint256 termsExpiry;
    }
}

interface ISponsorshipNotary {
    struct SponsorshipParams {
        uint256 price;
        uint256 debtId;
        uint256 listingNonce;
        uint256 termsExpiry;
    }
}

interface IRefinanceNotary {
    struct RefinanceParams {
        uint256 price;
        uint256 debtId;
        uint256 listingNonce;
        uint256 termsExpiry;
        bytes32 contractTerms;
    }
}
