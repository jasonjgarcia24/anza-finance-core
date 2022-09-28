// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractNotary.sol";
import "./AContractTreasurer.sol";
import "./AContractScheduler.sol";

abstract contract AContractManager is
    AContractNotary,
    AContractTreasurer,
    AContractScheduler
{
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

    /**
     * @dev Emitted when loan contract term(s) are updated.
     */
    event TermsChanged(
        string[] params,
        uint256[] prevValues,
        uint256[] newValues
    );

    function updateTerms(string[] memory _params, uint256[] memory _newValues)
        external
        onlyRole(_BORROWER_ROLE_)
    {
        require(
            _params.length == _newValues.length,
            "Input array parameters must be of equal length."
        );
        require(
            _params.length <= 3,
            "Input array parameters must be no more than 3."
        );

        if (lenderSigned_.get()) {
            _unsignLender();
        }

        uint256[] memory _prevValues = new uint256[](_params.length);

        for (uint256 i; i < _params.length; i++) {
            bytes32 _thisParam = keccak256(bytes(_params[i]));

            if (_thisParam == keccak256(bytes("principal"))) {
                _prevValues[i] = principal_.get();
                principal_.set(_newValues[i], uint256(state));
            } else if (_thisParam == keccak256(bytes("fixed_interest_rate"))) {
                _prevValues[i] = fixedInterestRate_.get();
                fixedInterestRate_.set(_newValues[i], uint256(state));
            } else if (_thisParam == keccak256(bytes("duration"))) {
                _prevValues[i] = duration_.get();
                _newValues[i] = _newValues[i].daysToBlocks();
                duration_.set(_newValues[i], uint256(state));
            } else {
                revert(
                    "`_params` must include strings 'principal', 'fixed_interest_rate', or 'duration' only."
                );
            }
        }

        emit TermsChanged(_params, _prevValues, _newValues);
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
        LoanState _prevState = state;

        // Update loan contract and activate loan
        state = LoanState.ACTIVE_OPEN;
        balance_.set(principal_.get(), uint256(state));
        accountBalance[lender_.get()] -= principal_.get();
        accountBalance[borrower_] += principal_.get();

        emit LoanStateChanged(_prevState, state);
    }
}
