// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AProposalAffirm.sol";

abstract contract AProposalNotary is AProposalAffirm {
    // /**
    //  * @dev Emitted when a loan agreement is signed off.
    //  */
    // event LoanSignoffChanged(
    //     address indexed signer,
    //     uint256 indexed action,
    //     bool borrowerSignStatus,
    //     bool lenderSignStatus
    // );

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
    function _signBorrower(address _loanContractAddress) internal {
        // IContract _loanContract = IContract(_loanContractAddress);

        // require(
        //     isApproved(msg.sender, _tokenContract, _tokenId),
        //     "Account is not approved."
        // );
        // require(
        //     _loanAgreement.borrowerSigned == false,
        //     "The borrower must not currently be signed off."
        // );
        // require(
        //     _loanAgreement.state < LoanState.ACTIVE_GRACE_COMMITTED,
        //     "Funds withdrawal illegal once the loan is active."
        // );

        // // Transfer token to contract
        // IERC721(_tokenContract).safeTransferFrom(
        //     msg.sender,
        //     address(this),
        //     _tokenId
        // );

        // // Update loan agreement
        // _loanAgreement.borrowerSigned = true;

        // emit LoanSignoffChanged(
        //     msg.sender, 1,  _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        // );
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
        // LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
        //     _tokenId
        // ][_loanId];

        // require(
        //     _loanAgreement.borrowerSigned == true,
        //     "The borrower must currently be signed off."
        // );
        // require(
        //     _loanAgreement.state < LoanState.ACTIVE_GRACE_COMMITTED,
        //     "Collateral withdrawal illegal once the loan is active."
        // );

        // // Transfer token to borrower
        // IERC721(_tokenContract).safeTransferFrom(
        //     address(this),
        //     msg.sender,
        //     _tokenId
        // );

        // // Update loan agreement
        // _loanAgreement.borrowerSigned = false;
        // _loanAgreement.state = LoanState.NONLEVERAGED;

        // emit LoanSignoffChanged(
        //     msg.sender, 0,  _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
        // );
    }

    // /**
    //  * @dev Sign lender for loan agreement.
    //  *
    //  * Requirements:
    //  *
    //  * - The caller must be the lender.
    //  * - The lender must not currently be signed off.
    //  * - The msg.value must equal the loan agreement principal.
    //  *
    //  * Emits {LoanSignoffChanged} events.
    //  */
    // function _signLender(
    //     address _tokenContract,
    //     uint256 _tokenId,
    //     uint256 _loanId
    // ) internal {
    //     // LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
    //     //     _tokenId
    //     // ][_loanId];

    //     // require(msg.sender == _loanAgreement.lender, "The caller must be the lender.");
    //     // require(_loanAgreement.lenderSigned == false, "The lender must not currently be signed off.");
    //     // require(msg.value >= _loanAgreement.principal, "Paid value must equal the loan agreement principal.");

    //     // LoanState _prevState = _loanAgreement.state;

    //     // // Update loan agreement
    //     // _loanAgreement.lenderSigned = true;
    //     // _loanAgreement.state = LoanState.SPONSORED;

    //     // emit LoanSignoffChanged(
    //     //     msg.sender, 1, _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
    //     // );
    //     // emit LoanStateChanged(_prevState, _loanAgreement.state);
    // }

    // /**
    //  * @dev Remove lender signoff for loan agreement.
    //  *
    //  * Requirements:
    //  *
    //  * - The msg.sender must be the owner, approver, owner's operator, or the lender.
    //  *
    //  * Emits {LoanSignoffChanged} events.
    //  */
    // function _withdrawLender() internal {
    //     require(
    //         msg.sender == _loanAgreement.lender ||
    //         isApproved(msg.sender, _tokenContract, _tokenId),
    //         "The caller must be the owner, approver, owner's operator, or the lender."
    //     );

    //     // LoanState _prevState = _loanAgreement.state;

    //     // // Update loan agreement
    //     // _loanAgreement.lenderSigned = false;
    //     // _loanAgreement.state = LoanState.UNSPONSORED;

    //     // emit LoanSignoffChanged(
    //     //     msg.sender, 0, _loanAgreement.borrowerSigned, _loanAgreement.lenderSigned
    //     // );
    //     // emit LoanStateChanged(_prevState, _loanAgreement.state);
    // }
}