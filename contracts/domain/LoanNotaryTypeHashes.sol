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
bytes32 constant _DEBT_LISTING_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "DebtListingParams(uint256 price,uint256 debtId,uint256 debtListingNonce,uint256 termsExpiry)"
);
