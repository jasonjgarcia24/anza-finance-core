// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IProposal.sol";

abstract contract AProposalGlobals is IProposal {
    // Token Contract => Token ID => Loan ID
    mapping(address => mapping(uint256 =>  uint256)) internal loanId;

    // NFT => Token ID => LoanAgreement[Loan ID]
    mapping(address => mapping(uint256 => LoanAgreement[])) internal loanAgreements;
}