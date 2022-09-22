// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AProposalAffirm.sol";
import "./AProposalNotary.sol";
import "./AProposalTreasurer.sol";

abstract contract AProposalManager is
    AProposalAffirm,
    AProposalNotary,
    AProposalTreasurer
{
    /**
     * @dev Open a loan agreement.
     *
     * Requirements:
     *
     * - `tokenContract` cannot be the zero address.
     * - The caller must be the token owner, approver, or the owner's operator.
     *
     * Emits {LoanStateChanged} and {LoanProposalCreated} events.
     */
    function createLoanContract(
        address tokenContract,
        uint256 tokenId,
        uint256 principal,
        uint256 fixedInterestRate,
        uint256 duration
    ) public virtual;

    /**
     * @dev Set loan agreement lender.
     *
     * Requirements:
     *
     * - When the caller is not the token owner, approver, nor the owner's operator, the lender is set to msg.sender and the lender signature is added.
     * - When the caller is the token owner, approver, or the owner's operator, the lender is set to address(0) and the lender signature is removed.
     *
     * Emits {LoanStateChanged} and {LoanLenderChanged} events.
     */
    function setLender(
        address tokenContract,
        uint256 tokenId,
        uint256 loanId
    ) public payable virtual;

    /**
     * @dev Set loan agreement parameter.
     *
     * Requirements:
     *
     * - The current loan agreement must exist.
     *
     * Emits {LoanParamChanged} events.
     */
    function setLoanParam(
        address tokenContract,
        uint256 tokenId,
        uint256 loanId,
        string[] memory param,
        uint256[] memory newValue
    ) external virtual;

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
     * @dev Returns the balance of the loan agreements for `tokenContract`, `tokenId`, `loanId` loan.
     *
     * Requirements: NONE
     */
    function getLoanBalance(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (uint256) {
        return loanAgreements[_tokenContract][_tokenId][_loanId].balance;
    }

    /**
     * @dev Returns the signoff status of the loan agreements for `tokenContract`, `tokenId`, `loanId` loan.
     *
     * Requirements: NONE
     */
    function getLoanSignoffs(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (bool[2] memory) {
        return [
            loanAgreements[_tokenContract][_tokenId][_loanId].borrowerSigned,
            loanAgreements[_tokenContract][_tokenId][_loanId].lenderSigned
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
    ) public view returns (address) {
        return loanAgreements[_tokenContract][_tokenId][_loanId].lender;
    }

    /**
     * @dev Returns the loan lender.
     *
     * Requirements: NONE
     */
    function getState(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (LoanState) {
        return loanAgreements[_tokenContract][_tokenId][_loanId].state;
    }
}
