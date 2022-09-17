// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ILoanAgreement.sol";

abstract contract ALoanManager is ILoanAgreement {
    // NFT => Token ID => LoanAgreement[Loan ID]
    mapping(address => mapping(uint256 => LoanAgreement[]))
        internal loanAgreements;

    address[] internal borrowers;

    /**
     * @dev Emitted when a loan agreement is created for a ERC721 token.
     */
    event LoanAgreementCreated(
        uint256 indexed loanId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when a loan agreement state is changed.
     */
    event LoanStateChanged(
        LoanState indexed prevState,
        LoanState indexed newState
    );

    /**
     * @dev Open a loan agreement.
     *
     * Requirements:
     *
     * - `tokenContract` cannot be the zero address.
     * - The caller must be the token owner, approver, or the owner's operator.
     *
     * Emits {LoanStateChanged} and {LoanAgreementCreated} events.
     */
    function createLoanProposal(
        address tokenContract,
        uint256 tokenId,
        uint256 principal,
        uint256 fixedInterestRate,
        uint256 duration
    ) public virtual;

    /**
     * @dev Returns the count of loan agreements submitted for `tokenContract` and `tokenId` ERC721 token.
     *
     * Requirements: NONE
     */

    function getLoanCount(address _tokenContract, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return loanAgreements[_tokenContract][_tokenId].length - 1;
    }

    /**
     * @dev Returns the terms of the loan agreements for `tokenContract`, `tokenId`, `loanId` loan.
     *
     * Requirements: NONE
     */
    function getLoanTerms(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (uint256[3] memory) {
        return [
            loanAgreements[_tokenContract][_tokenId][_loanId].principal,
            loanAgreements[_tokenContract][_tokenId][_loanId].fixedInterestRate,
            loanAgreements[_tokenContract][_tokenId][_loanId].duration
        ];
    }

    /**
     * @dev Returns the loan agreements status for `tokenContract`, `tokenId`, and `loanId` loan.
     *
     * Requirements: NONE
     */
    function getLoanState(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (LoanState) {
        return loanAgreements[_tokenContract][_tokenId][_loanId].state;
    }

    /**
     * @dev Returns the loan lender.
     *
     * Requirements: NONE
     */
    function getLender(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (LoanState) {
        return loanAgreements[_tokenContract][_tokenId][_loanId].lender;
    }
}
