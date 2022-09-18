// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ILoanAgreement.sol";
import "./ALoanAffirm.sol";

abstract contract ALoanManager is ALoanAffirm {
    address[] internal borrowers;
    mapping(address => uint256) internal accountWithdrawalLimit;

    /**
     * @dev Emitted when a loan agreement is created for a ERC721 token.
     */
    event LoanProposalCreated(
        uint256 indexed loanId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

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
    function createLoanProposal(
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
     * @dev Returns if the `_tokenContract`, `tokenId`, and `_loanId`
     * loan exists.
     *
     * Requirements: NONE
     */
    function isExistingLoanProposal(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (bool) {
        return loanAgreements[_tokenContract][_tokenId].length >= _loanId;
    }

    /**
     * @dev Funds the loan proposal.
     *
     * Requirements:
     *
     * - The caller must be the lender.
     * - The loan proposal state must be `LoanState.SPONSORED`.
     *
     */
    function _fundLoanProposal(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        require(msg.sender == _loanAgreement.lender, "The caller must be the lender.");
        require(_loanAgreement.state == LoanState.SPONSORED, "The loan state must be LoanState.SPONSORED.");

        payable(address(this)).transfer(msg.value);
        _loanAgreement.state = LoanState.FUNDED;
    }

    /**
     * @dev Defunds the loan proposal.
     *
     * Requirements:
     *
     * - The caller must be the owner, approver, owner's operator, or lender.
     * - The loan proposal state must be LoanState.FUNDED.
     *
     */
    function _defundLoanProposal(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        require(
            msg.sender == _loanAgreement.lender ||
            isApproved(msg.sender, _tokenContract, _tokenId),
            "The caller must be the owner, approver, owner's operator, or lender."
        );
        require(_loanAgreement.state == LoanState.FUNDED, "The loan state must be LoanState.FUNDED.");

        _loanAgreement.balance = 0;
        accountWithdrawalLimit[_loanAgreement.lender] = _loanAgreement.balance;
    }
}
