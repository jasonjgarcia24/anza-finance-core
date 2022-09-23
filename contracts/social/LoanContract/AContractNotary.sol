// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractGlobals.sol";

abstract contract AContractNotary is AContractGlobals {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;

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
            borrowerSigned.get() == false,
            "The borrower must not currently be signed off."
        );
        LoanState _prevState = state;

        // Update loan contract
        borrowerSigned.set(true, uint256(state));
        _grantRole(_PARTICIPANT_ROLE_, borrower.get());
        state = state > LoanState.NONLEVERAGED
            ? lenderSigned.get() ? LoanState.FUNDED : LoanState.UNSPONSORED
            : state;

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
    function _unsignBorrower() internal {
        require(
            borrowerSigned.get() == true,
            "The borrower must currently be signed off."
        );
        LoanState _prevState = state;

        // Update loan contract
        borrowerSigned.set(false, uint256(state));

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
            lenderSigned.get() == false,
            "The lender must not currently be signed off."
        );
        require(
            msg.value + accountBalance[_msgSender()] >= principal.get(),
            "Paid value and the account balance must be at least the loan principal."
        );
        LoanState _prevState = state;

        // Update loan contract
        lender.set(_msgSender(), uint256(state));
        lenderSigned.set(true, uint256(state));
        _grantRole(_PARTICIPANT_ROLE_, lender.get());
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
    function _unsignLender() internal {
        require(
            lenderSigned.get() == true,
            "The lender must currently be signed off."
        );
        LoanState _prevState = state;

        // Update loan agreement
        lender.set(address(0), uint256(state));
        lenderSigned.set(false, uint256(state));
        state = LoanState.UNSPONSORED;

        emit LoanStateChanged(_prevState, state);
    }
}
