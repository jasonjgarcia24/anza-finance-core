// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AProposalAffirm.sol";

abstract contract AProposalContractInteractions is AProposalAffirm {
    /**
     * @dev Emitted when a loan contract is deployed.
     */
    event LoanContractDeployed(
        address indexed loanContract,
        address indexed borrower,
        address indexed lender,
        address tokenContract,
        uint256 tokenId
    );

     /**
     * @dev Create the loan contract from the loan proposal terms when loan proposal `tokenContract`, `tokenId`, and `loanId` is signed off by both borrower and lender.
     *
     * Requirements:
     * 
     * - LoanProposal `tokenContract`, `tokenId`, and `loanId` must exist
     * - LoanProposal `tokenContract`, `tokenId`, and `loanId` must be signed off by both the borrower and lender
     *
     */
     function _deployLoanContract(address tokenContract, uint256 tokenId, uint256 loanId) internal virtual;
     
     /**
     * @dev Determine if the loan contract is deployable.
     *
     * Requirements: NONE
     *
     */
     function _isDeployable(address _tokenContract, uint256 _tokenId, uint256 _loanId) internal view returns (bool) {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        address _owner = IERC721(_tokenContract).ownerOf(_tokenId);
        bool _isSigned = _loanAgreement.borrowerSigned && _loanAgreement.lenderSigned;
        bool _isCollateralized = _owner == address(this);
        
        return _isSigned && _isCollateralized;
     }
}