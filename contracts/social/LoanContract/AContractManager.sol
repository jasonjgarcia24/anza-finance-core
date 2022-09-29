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

        if (lenderSigned.get()) {
            _unsignLender();
        }

        uint256[] memory _prevValues = new uint256[](_params.length);

        for (uint256 i; i < _params.length; i++) {
            bytes32 _thisParam = keccak256(bytes(_params[i]));

            if (_thisParam == keccak256(bytes("principal"))) {
                _prevValues[i] = principal.get();
                principal.set(_newValues[i], uint16(state));
            } else if (_thisParam == keccak256(bytes("fixed_interest_rate"))) {
                _prevValues[i] = fixedInterestRate.get();
                fixedInterestRate.set(_newValues[i], uint16(state));
            } else if (_thisParam == keccak256(bytes("duration"))) {
                _prevValues[i] = duration.get();
                _newValues[i] = _newValues[i].daysToBlocks();
                duration.set(_newValues[i], uint16(state));
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
        balance.set(principal.get(), uint16(state));
        accountBalance[lender.get()] -= principal.get();
        accountBalance[borrower] += principal.get();

        emit LoanStateChanged(_prevState, state);
    }
}
