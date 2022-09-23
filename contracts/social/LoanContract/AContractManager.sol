// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractNotary.sol";
import "./AContractTreasurer.sol";

abstract contract AContractManager is AContractNotary, AContractTreasurer {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;

    function updateTerms(string[] memory _params, uint256[] memory _newValues) external onlyRole(_BORROWER_ROLE_) {
        require(_params.length == _newValues.length, "Input array parameters must be of equal length.");
        require(_params.length <= 3, "Input array parameters must be no more than 3.");

        if (lenderSigned.get()) { _unsignLender(); }

        for (uint256 i; i < _params.length; i++) {
            bytes32 _paramHash = keccak256(bytes(_params[i]));

            if (_paramHash == keccak256(bytes("principal"))) {
                principal.set(_newValues[i], uint256(state));
            } else if (_paramHash == keccak256(bytes("fixed_interest_rate"))) {
                fixedInterestRate.set(_newValues[i], uint256(state));
            } else if (_paramHash == keccak256(bytes("duration"))) {
                duration.set(_newValues[i], uint256(state));
            } else {
                revert("`_params` must include strings 'principal', 'fixed_interest_rate', or 'duration' only.");
            }
        }
    }

    /**
     * @dev The loan contract becomes active and the funds are withdrawable.
     *
     * Requirements:
     * 
     * - LoanState must be FUNDED (check with caller function).
     * - Lender and borrower must be signed off.
     *
     * Emits {LoanStateChanged} events.
     */
    function _activateLoan() internal {
        require(
            borrowerSigned.get() == true && lenderSigned.get() == true,
            "The loan contract must be fully signed off."
        );
        LoanState _prevState = state;

        // Update loan contract and activate loan
        state = LoanState.ACTIVE_OPEN;
        accountBalance[lender.get()] -= principal.get();
        accountBalance[borrower.get()] += principal.get();

        emit LoanStateChanged(_prevState, state);
    }
}
