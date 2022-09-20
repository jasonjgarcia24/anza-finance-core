// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AProposalManager.sol";
import "./AProposalContractInteractions.sol";
import "./LoanContract.sol";

contract LoanProposal is AProposalManager, AProposalContractInteractions {
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
        require(
            isApproved(msg.sender, _tokenContract, _tokenId),
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
        _loanAgreements[_loanId].borrower = IERC721(_tokenContract).ownerOf(_tokenId);
        _loanAgreements[_loanId].priority = _loanId;
        _loanAgreements[_loanId].principal = _principal;
        _loanAgreements[_loanId].fixedInterestRate = _fixedInterestRate;
        _loanAgreements[_loanId].duration = _duration;
        _loanAgreements[_loanId].state = LoanState.UNSPONSORED;
        sign(_tokenContract, _tokenId, _loanId);

        emit LoanStateChanged(_prevState, _loanAgreements[_loanId].state);
        emit LoanProposalCreated(_loanId, _tokenContract, _tokenId);
    }

    function setLender(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public payable override {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        address _prevLender = _loanAgreement.lender;
        bool _isApproved = isApproved(msg.sender, _tokenContract, _tokenId);
        
        require(_isApproved || !_loanAgreement.lenderSigned, "The lender can only set the lender if the current lender signed state is false.");

        if (_isApproved) {            
            _defundLoanProposal(_tokenContract, _tokenId, _loanId);
            _withdrawLender(_tokenContract, _tokenId, _loanId);
            _loanAgreement.lender = address(0);
            _loanAgreement.state = _loanAgreement.state == LoanState.NONLEVERAGED
                ? _loanAgreement.state
                : LoanState.UNSPONSORED;
        } else {
            _loanAgreement.lender = msg.sender;
            _signLender(_tokenContract, _tokenId, _loanId);
            _fundLoanProposal(_tokenContract, _tokenId, _loanId);
        }

        emit LoanLenderChanged(_prevLender, _loanAgreement.lender);
    }

    function sign(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public payable {
        require(
            isApproved(msg.sender, _tokenContract, _tokenId),
            "Only the borrower can sign. If lending, use setLender()"
        );

        _signBorrower(_tokenContract, _tokenId, _loanId);

        if (_isDeployable(_tokenContract, _tokenId, _loanId)) {
            _deployLoanContract(_tokenContract, _tokenId, _loanId);
        }
    }

    function withdraw(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) public {
        if (isBorrower(_tokenContract, _tokenId, _loanId)) {
            _withdrawBorrower(_tokenContract, _tokenId, _loanId);
        } else {
            _defundLoanProposal(_tokenContract, _tokenId, _loanId);
            _withdrawLender(_tokenContract, _tokenId, _loanId);
        }
    }

    function setLoanParam(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId,
        string[] memory _params,
        uint256[] memory _newValues
    ) external override {
        require(
            isExistingLoanProposal(_tokenContract, _tokenId, _loanId),
            "The loan does not exist."
        );

        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        uint256 _prevValue;

        for (uint256 i; i < _params.length; i++) {
            bytes32 _paramHash = keccak256(bytes(_params[i]));

            if (_paramHash == keccak256(bytes("principal"))) {
                _prevValue = _loanAgreement.principal;
                _loanAgreement.principal = _newValues[i];
            } else if (_paramHash == keccak256(bytes("fixed_interest_rate"))) {
                _prevValue = _loanAgreement.fixedInterestRate;
                _loanAgreement.fixedInterestRate = _newValues[i];
            } else if (_paramHash == keccak256(bytes("duration"))) {
                _prevValue = _loanAgreement.duration;
                _loanAgreement.duration = _newValues[i];
            } else {
                require(
                    false,
                    "Input `_params` must be one of the strings 'principal', 'fixed_interest_rate', or 'duration'."
                );
            }
        }

        emit LoanParamChanged(
            keccak256(bytes(_params[_params.length - 1])),
            _prevValue,
            _newValues[_params.length - 1]
        );
    }

    function _deployLoanContract(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal override {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        LoanContract _loanContract = new LoanContract(
            _loanAgreement.borrower,
            _loanAgreement.lender,
            _tokenContract,
            _tokenId,
            _loanAgreement.priority,
            _loanAgreement.fixedInterestRate,
            _loanAgreement.duration,
            _loanAgreement.balance
        );

        address _loanContractAddress = address(_loanContract);

        IERC721(_tokenContract).approve(
            _loanContractAddress,
            _tokenId
        );

        IERC721(_tokenContract).safeTransferFrom(
            address(this),
            _loanContractAddress,
            _tokenId
        );

        emit LoanContractDeployed(
            _loanContractAddress,
            _loanAgreement.borrower,
            _loanAgreement.lender,
            _tokenContract,
            _tokenId
        );
    }

    receive() external payable {}
}
