// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";
import "./ALoanManager.sol";

contract LoanProposal is ALoanManager {
    function createLoanProposal(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) public override {
        require(
            _tokenContract != address(0),
            "Collateral cannot be address 0."
        );

        // Verify msg.sender access rights to token
        IERC721 _erc721 = IERC721(_tokenContract);
        address _borrower = _erc721.ownerOf(_tokenId);
        require(
            msg.sender == _borrower ||
                msg.sender == _erc721.getApproved(_tokenId) ||
                _erc721.isApprovedForAll(_borrower, msg.sender),
            "The caller must be the token owner, approver, or the owner's operator."
        );

        // Create new loan agreement
        LoanAgreement[] storage _loanAgreements = loanAgreements[
            _tokenContract
        ][_tokenId];
        uint256 _loanId = _loanAgreements.length;
        _loanAgreements.push();

        // Set loan agreement conditions
        LoanState _prevState = _loanAgreements[_loanId].state;
        _loanAgreements[_loanId].priority = _loanId;
        _loanAgreements[_loanId].principal = _principal;
        _loanAgreements[_loanId].fixedInterestRate = _fixedInterestRate;
        _loanAgreements[_loanId].duration = _duration;
        _loanAgreements[_loanId].state = LoanState.PENDING_UNSPONSORED;

        emit LoanStateChanged(_prevState, _loanAgreements[_loanId].state);
        emit LoanAgreementCreated(_loanId, _tokenContract, _tokenId);
    }

    function setLender(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public {
        LoanAgreement storage _loanAgreement = loanAgreements[
            _tokenContract
        ][_tokenId][_loanId];

        LoanState _prevState = _loanAgreement.state;
        _loanAgreement.lender = msg.sender;
        _loanAgreement.state = LoanState.PENDING_SPONSORED;

        emit LoanStateChanged(_prevState, _loanAgreement.state);
    }
}
