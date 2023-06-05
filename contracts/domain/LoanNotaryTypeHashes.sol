// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *           Loan Contract Type Hashes              *
 * ------------------------------------------------ */
bytes32 constant _CONTRACT_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "ContractParams(uint256 principal,bytes32 contractTerms,address collateralAddress,uint256 collateralId,uint256 collateralNonce)"
);

/* ------------------------------------------------ *
 *        Anza Debt Storefront Type Hashes          *
 * ------------------------------------------------ */
bytes32 constant _LISTING_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "ListingParams(uint256 price,uint256 debtId,uint256 listingNonce,uint256 termsExpiry)"
);
