// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

bytes32 constant CONTRACT_INTIALIZED_EVENT_SIG = keccak256(
    "ContractInitialized(address,uint256,uint256,uint256)"
);

bytes32 constant PROPOSAL_REVOKED_EVENT_SIG = keccak256(
    "ProposalRevoked(address,uint256,uint256,bytes32)"
);

interface ILoanContractEvents {
    event ContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId,
        uint256 activeLoanIndex
    );

    event ProposalRevoked(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed collateralNonce,
        bytes32 contractTerms
    );
}
