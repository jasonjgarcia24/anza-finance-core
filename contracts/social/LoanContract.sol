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
        balance = 0;
        borrowerSigned = false;
        lenderSigned = false;
        state = LoanState.NONLEVERAGED;

        _setupRole(_ARBITER_ROLE_, address(this));
        _setupRole(_BORROWER_ROLE_, borrower);
        __sign();
    }

    function withdrawNft() external onlyRole(_BORROWER_ROLE_) {
        _withdrawBorrower();
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