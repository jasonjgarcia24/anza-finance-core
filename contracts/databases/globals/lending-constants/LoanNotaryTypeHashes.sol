// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *           EIP712 Domain Type Hashes              *
 * ------------------------------------------------ */
bytes32 constant _TYPE_HASH_ = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

/* ------------------------------------------------ *
 *           Loan Contract Type Hashes              *
 * ------------------------------------------------ */
bytes32 constant _CONTRACT_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "ContractParams(uint256 principal,bytes32 contractTerms,address collateralAddress,uint256 collateralId,uint256 collateralNonce)"
);

/* ------------------------------------------------ *
 *        Anza Debt Storefront Type Hashes          *
 * ------------------------------------------------ */
bytes32 constant _DEBT_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "DebtParams(uint256 price,address collateralAddress,uint256 collateralId,uint256 listingNonce,uint256 termsExpiry)"
);
bytes32 constant _SPONSORSHIP_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "SponsorshipParams(uint256 price,uint256 debtId,uint256 listingNonce,uint256 termsExpiry)"
);
bytes32 constant _REFINANCE_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "RefinanceParams(uint256 price,uint256 debtId,uint256 listingNonce,bytes32 contractTerms)"
);
