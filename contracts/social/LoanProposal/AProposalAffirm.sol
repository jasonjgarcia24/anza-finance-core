// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AProposalGlobals.sol";

abstract contract AProposalAffirm is AProposalGlobals {
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
}