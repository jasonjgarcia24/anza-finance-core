// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IContract.sol";

contract LoanContract is IContract {
    LoanContract public loanContract;

    constructor(
        address _borrower,
        address _lender,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _fixedInterestRate,
        uint256 _duration,
        uint256 _balance
    ) {
        loanContract.borrower = _borrower;
        loanContract.lender = _lender;
        loanContract.tokenContract = _tokenContract;
        loanContract.tokenId = _tokenId;
        loanContract.priority = _priority;
        loanContract.fixedInterestRate = _fixedInterestRate;
        loanContract.duration = _duration;
        loanContract.balance = _balance;
    }
}