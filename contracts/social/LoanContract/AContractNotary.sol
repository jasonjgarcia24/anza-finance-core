// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractAffirm.sol";

abstract contract AContractNotary is AContractAffirm {
    function _signBorrower() internal {
        require(
            borrowerSigned == false && state <= LoanState.NONLEVERAGED,
            "The borrower must not currently be signed off."
        );
        LoanState _prevState = state;

        // If called by borrower, transfer token to contract
        if (_msgSender() == borrower) {
            IERC721(tokenContract).safeTransferFrom(borrower, address(this), tokenId);
        }

        // Update loan contract
        borrowerSigned = true;
        state = lenderSigned ? LoanState.FUNDED : LoanState.UNSPONSORED;

        emit LoanStateChanged(_prevState, state);
    }

    function _withdrawBorrower() internal {
        require(
            borrowerSigned == true && state > LoanState.NONLEVERAGED,
            "The borrower must currently be signed off."
        );
        require(
            state < LoanState.FUNDED,
            "Collateral withdrawal illegal once the loan is active."
        );
        LoanState _prevState = state;

        // Transfer token to borrower
        IERC721(tokenContract).safeTransferFrom(address(this), borrower, tokenId);

        // Update loan agreement
        borrowerSigned = false;
        state = LoanState.NONLEVERAGED;

        emit LoanStateChanged(_prevState, state);
    }
}