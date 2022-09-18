// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ILoanAgreement.sol";
import "hardhat/console.sol";

abstract contract ALoanAffirm is ILoanAgreement {
    // NFT => Token ID => LoanAgreement[Loan ID]
    mapping(address => mapping(uint256 => LoanAgreement[]))
        internal loanAgreements;

    /**
     * @dev Emitted when a loan agreement is signed off.
     */
    event LoanSignoffChanged(
        address indexed signer,
        uint256 indexed position,
        bool borrowerSignStatus,
        bool lenderSignStatus
    );

    /**
     * @dev Sign borrower for loan agreement.
     *
     * Requirements:
     *
     * - The msg.sender must be the owner, approver, owner's operator.
     * - The borrower must not currently be signed off.
     *
     * Emits {LoanSignoffChanged} events.
     */
    function _signBorrower(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        require(
            _loanAgreement.borrowerSigned == false,
            "Only unsigned agreements can be signed."
        );

        // Deposit token to contract
        IERC721(_tokenContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        // Update loan agreement
        _loanAgreement.borrowerSigned = true;

        address _owner = IERC721(_tokenContract).ownerOf(_tokenId);
        emit LoanSignoffChanged(
            _owner, 0,  _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        );
    }

    /**
     * @dev Remove borrower signoff for loan agreement.
     *
     * Requirements:
     *
     * - The msg.sender must be the owner, approver, or owner's operator.
     *
     * Emits {LoanSignoffChanged} events.
     */
    function _unsignBorrower(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        require(
            isApproved(msg.sender, _tokenContract, _tokenId),
            "The caller must be the owner, approver, or owner's operator."
        );

        // Update loan agreement
        _loanAgreement.borrowerSigned = false;

        address _owner = IERC721(_tokenContract).ownerOf(_tokenId);
        emit LoanSignoffChanged(
            _owner, 0,  _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        );
    }

    /**
     * @dev Sign lender for loan agreement.
     *
     * Requirements:
     *
     * - The caller must be the lender.
     * - The lender must not currently be signed off.
     * - The msg.value must equal the loan agreement principal.
     *
     * Emits {LoanSignoffChanged} events.
     */
    function _signLender(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        require(msg.sender == _loanAgreement.lender, "The caller must be the lender.");
        require(_loanAgreement.lenderSigned == false, "The lender must not currently be signed off.");
        require(msg.value >= _loanAgreement.principal, "Paid value must equal the loan agreement principal.");

        // Update loan agreement
        _loanAgreement.lenderSigned = true;
        _loanAgreement.balance = msg.value;
        _loanAgreement.state = LoanState.SPONSORED;

        emit LoanSignoffChanged(
            msg.sender, 1, _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        );
    }

    /**
     * @dev Remove lender signoff for loan agreement.
     *
     * Requirements:
     *
     * - The msg.sender must be the owner, approver, owner's operator, or the lender.
     *
     * Emits {LoanSignoffChanged} events.
     */
    function _unsignLender(
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
            "The caller must be the owner, approver, owner's operator, or the lender."
        );

        // Update loan agreement
        _loanAgreement.lenderSigned = false;
        _loanAgreement.state = LoanState.UNSPONSORED;

        emit LoanSignoffChanged(
            msg.sender, 1, _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        );
    }

    /**
     * @dev Returns the `_approver` status as owner, approver, or
     * owner's operator.
     *
     * Requirements: NONE
     */
    function isApproved(
        address _approver,
        address _tokenContract,
        uint256 _tokenId
    ) public view returns (bool) {
        IERC721 _erc721 = IERC721(_tokenContract);
        address _owner = _erc721.ownerOf(_tokenId);

        bool _isApproved = 
            _approver == _owner ||
            _approver == _erc721.getApproved(_tokenId) ||
            _erc721.isApprovedForAll(_owner, _approver);

        return _isApproved;
    }

}