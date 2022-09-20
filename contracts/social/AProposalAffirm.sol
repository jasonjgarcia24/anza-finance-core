// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IProposal.sol";

abstract contract AProposalAffirm is IProposal {
    // NFT => Token ID => LoanAgreement[Loan ID]
    mapping(address => mapping(uint256 => LoanAgreement[]))
        internal loanAgreements;

    /**
     * @dev Emitted when a loan agreement is signed off.
     */
    event LoanSignoffChanged(
        address indexed signer,
        uint256 indexed action,
        bool borrowerSignStatus,
        bool lenderSignStatus
    );

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

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
            isApproved(msg.sender, _tokenContract, _tokenId),
            "Account is not approved."
        );
        require(
            _loanAgreement.borrowerSigned == false,
            "The borrower must not currently be signed off."
        );
        require(
            _loanAgreement.state < LoanState.ACTIVE_GRACE_COMMITTED,
            "Funds withdrawal illegal once the loan is active."
        );

        // Transfer token to contract
        IERC721(_tokenContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        // Update loan agreement
        _loanAgreement.borrowerSigned = true;

        emit LoanSignoffChanged(
            msg.sender, 1,  _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        );
    }

    /**
     * @dev Remove borrower signoff for loan agreement.
     *
     * Requirements:
     * 
     * - The borrower must currently be signed off.
     *
     * Emits {LoanSignoffChanged} events.
     */
    function _withdrawBorrower(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        require(
            _loanAgreement.borrowerSigned == true,
            "The borrower must currently be signed off."
        );
        require(
            _loanAgreement.state < LoanState.ACTIVE_GRACE_COMMITTED,
            "Collateral withdrawal illegal once the loan is active."
        );

        // Transfer token to borrower
        IERC721(_tokenContract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        // Update loan agreement
        _loanAgreement.borrowerSigned = false;
        _loanAgreement.state = LoanState.NONLEVERAGED;

        emit LoanSignoffChanged(
            msg.sender, 0,  _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
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

        LoanState _prevState = _loanAgreement.state;

        // Update loan agreement
        _loanAgreement.lenderSigned = true;
        _loanAgreement.state = LoanState.SPONSORED;

        emit LoanSignoffChanged(
            msg.sender, 1, _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        );
        emit LoanStateChanged(_prevState, _loanAgreement.state);
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
    function _withdrawLender(
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

        LoanState _prevState = _loanAgreement.state;

        // Update loan agreement
        _loanAgreement.lenderSigned = false;
        _loanAgreement.state = LoanState.UNSPONSORED;

        emit LoanSignoffChanged(
            msg.sender, 0, _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        );
        emit LoanStateChanged(_prevState, _loanAgreement.state);
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
    ) internal view returns (bool) {
        IERC721 _erc721 = IERC721(_tokenContract);
        address _owner = _erc721.ownerOf(_tokenId);

        bool _isApproved = 
            _approver == _owner ||
            _approver == _erc721.getApproved(_tokenId) ||
            _erc721.isApprovedForAll(_owner, _approver);

        return _isApproved;
    }

    /**
     * @dev Returns the `_approver` status as owner, approver, or
     * owner's operator.
     *
     * Requirements: NONE
     */
    function isBorrower(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal view returns (bool) {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        return msg.sender == _loanAgreement.borrower;
    }

    /**
     * @dev Returns the status of the lender and owner,
     * approver, or owner's operator signoff.
     *
     * Requirements: NONE
     */
    function isSigned(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public view returns (uint256) {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        if (_loanAgreement.lenderSigned && _loanAgreement.borrowerSigned) { return 3; }
        else if (_loanAgreement.borrowerSigned) { return 2; }
        else if (_loanAgreement.lenderSigned) { return 1; }
        else { return 0; }
    }
}