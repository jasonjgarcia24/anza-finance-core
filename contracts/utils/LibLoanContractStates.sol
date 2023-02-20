// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LibLoanContractStates {
    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(
        LoanState indexed prevState,
        LoanState indexed newState
    );

    enum LoanState {
        UNDEFINED,
        NONLEVERAGED,
        UNSPONSORED,
        SPONSORED,
        FUNDED,
        ACTIVE_GRACE_COMMITTED,
        ACTIVE_GRACE_OPEN,
        ACTIVE_COMMITTED,
        ACTIVE_OPEN,
        PAID,
        DEFAULT,
        COLLECTION,
        AUCTION,
        AWARDED,
        CLOSED
    }

    function getStateOnWithdrawal(LoanState _state)
        public
        pure
        returns (LoanState)
    {
        if (_state != LoanState.PAID) {
            return LoanState.NONLEVERAGED;
        }

        return _state;
    }

    function isActiveState(LoanState _state) public pure returns (bool) {
        return _state <= LoanState.FUNDED && _state >= LoanState.COLLECTION;
    }

    function isInactiveState(LoanState _state) public pure returns (bool) {
        return (_state < LoanState.FUNDED || _state > LoanState.COLLECTION);
    }

    function isWithdrawableState(LoanState _state) public pure returns (bool) {
        return (_state < LoanState.ACTIVE_GRACE_COMMITTED ||
            _state == LoanState.PAID);
    }

    function isDepositableState(LoanState _state) public pure returns (bool) {
        return (_state < LoanState.ACTIVE_GRACE_COMMITTED ||
            _state == LoanState.PAID);
    }
}
