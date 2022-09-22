// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LoanContract/AContractManager.sol";

contract LoanContract is AContractManager {
    constructor(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) {
        borrower = IERC721(_tokenContract).ownerOf(_tokenId);
        lender = address(0);
        tokenContract = _tokenContract;
        tokenId = _tokenId;
        priority = _priority;
        principal = _principal;
        fixedInterestRate = _fixedInterestRate;
        duration = _duration;
        borrowerSigned = false;
        lenderSigned = false;
        state = LoanState.NONLEVERAGED;

        _setupRole(_ARBITER_ROLE_, address(this));
        _setupRole(_BORROWER_ROLE_, borrower);
        __sign();
    }

    function setLender() external payable {
        if (isBorrower()) {
            _defundLoan();
            _revokeRole(_LENDER_ROLE_, lender);
            _withdrawLender();
        } else {
            _signLender();
            _setupRole(_LENDER_ROLE_, lender);
            _fundLoan();
        }
    }

    function withdrawNft() external onlyRole(_BORROWER_ROLE_) {
        _withdrawBorrower();
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw() public onlyRole(_PARTICIPANT_ROLE_) {
        _withdrawFunds(_msgSender());
    }
    
    function sign() external onlyRole(_BORROWER_ROLE_) {
        _signBorrower();

        // if (_isDeployable(_tokenContract, _tokenId, _loanId)) {
        //     _deployLoanContract(_tokenContract, _tokenId, _loanId);
        // }
    }
    
    function __sign() private {
        _signBorrower();
    }
}