// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILoanAgreement {
    enum LoanState {
        UNDEFINED,
        UNSPONSORED,
        SPONSORED,
        FUNDED,
        ACTIVE_GRACE_COMMITTED,
        ACTIVE_GRACE_OPEN,
        ACTIVE_COMMITTED,
        ACTIVE_OPEN,
        PAID,
        DEFAULT,
        AUCTION,
        CLOSED
    }

    struct LoanAgreement {
        address lender;
        uint256 priority;
        uint256 principal;
        uint256 fixedInterestRate;
        uint256 duration;
        uint256 balance;
        bool borrowerSigned;
        bool lenderSigned;
        LoanState state;
    }

    /**
     * @dev Emitted when a loan lender is changed.
     */
    event LoanLenderChanged(
        address indexed prevLender,
        address indexed newLender
    );    

    /**
     * @dev Emitted when a loan parameter is changed.
     */
    event LoanParamChanged(
        bytes32 indexed param,
        uint256 prevValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when a loan agreement state is changed.
     */
    event LoanStateChanged(
        LoanState indexed prevState,
        LoanState indexed newState
    );
}