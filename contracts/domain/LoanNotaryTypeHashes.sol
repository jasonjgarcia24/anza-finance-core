// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *           Loan Contract Type Hashes              *
 * ------------------------------------------------ */
bytes32 constant initLoanContract__typeHash0 = keccak256(
    "InitLoanContract(bytes32 _contractTerms,address _collateralAddress,uint256 _collateralId,bytes _borrowerSignature)"
);
bytes32 constant initLoanContract__typeHash1 = keccak256(
    "InitLoanContract(bytes32 _contractTerms,uint256 _debtId,bytes _borrowerSignature)"
);

/* ------------------------------------------------ *
 *        Anza Debt Storefront Type Hashes          *
 * ------------------------------------------------ */
bytes32 constant buyDebt__typeHash0 = keccak256(
    "BuyDebt(bytes32 _listingTerms,uint256 _debtId,bytes _sellerSignature)"
);
