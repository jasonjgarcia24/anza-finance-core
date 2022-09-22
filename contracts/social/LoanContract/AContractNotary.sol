// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractAffirm.sol";

abstract contract AContractNotary is AContractAffirm {
    /**
     * @dev The borrower signs the loan contract and transfers the collateral token.
     *
     * Requirements:
     *
     * - The borrower must not be signed off.
     * - The loan state must be les than `LoanState.NONLEVERAGED`.
     *
     * Emits {LoanStateChanged} events.
     */
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
        _grantRole(_PARTICIPANT_ROLE_, borrower);
        state = lenderSigned ? LoanState.FUNDED : LoanState.UNSPONSORED;

        emit LoanStateChanged(_prevState, state);
    }
    
    /**
     * @dev Withdraws the borrower's collateralized token from the loan contract.
     *
     * Requirements:
     *
     * - The borrower must be signed off.
     * - The loan state must be greater than `LoanState.NONLEVERAGED`.
     * - The loan state must be less than `LoanState.FUNDED`.
     *
     * Emits {LoanStateChanged} events.
     */
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
        _revokeRole(_PARTICIPANT_ROLE_, borrower);
        state = LoanState.NONLEVERAGED;

        emit LoanStateChanged(_prevState, state);
    }
    
    /**
     * @dev The lender signs and funds the loan contract.
     *
     * Requirements:
     *
     * - The lender must not be signed off.
     * - The loan state must be less than `LoanState.FUNDED`.
     * - Paid value and the account balance must be at least the loan principal.
     *
     * Emits {LoanStateChanged} events.
     */
    function _signLender() internal {
        require(
            lenderSigned == false && state <= LoanState.FUNDED,
            "The lender must not currently be signed off."
        );
        require(
            msg.value + accountBalance[lender] >= principal,
            "Paid value and the account balance must be at least the loan principal."
        );
        LoanState _prevState = state;

        // Update loan contract
        lender = _msgSender();
        lenderSigned = true;
        _grantRole(_PARTICIPANT_ROLE_, lender);
        state = LoanState.SPONSORED;

        emit LoanStateChanged(_prevState, state);
    }

    /**
     * @dev Remove lender signoff for loan agreement.
     *
     * Requirements:
     *
     * Emits {LoanStateChanged} events.
     */
    function _withdrawLender() internal {
        require(
            lenderSigned == true && state <= LoanState.FUNDED,
            "The lender must currently be signed off."
        );
        LoanState _prevState = state;

        // Update loan agreement
        lender = address(0);
        lenderSigned = false;
        _revokeRole(_PARTICIPANT_ROLE_, lender);
        state = LoanState.UNSPONSORED;

        emit LoanStateChanged(_prevState, state);
    }
}