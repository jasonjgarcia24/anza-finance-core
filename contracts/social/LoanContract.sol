// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LoanContract/AContractManager.sol";

contract LoanContract is AContractManager {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;

    uint256 public immutable priority;

    constructor(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) {       
        uint256 _uintState = uint256(state);
        uint256 _uintUndefined = uint256(LoanState.UNDEFINED);
        uint256 _uintFunded = uint256(LoanState.FUNDED);

        // Initialize state controlled variables
        borrower.init(_uintUndefined);
        tokenContract.init(_uintUndefined);
        tokenId.init(_uintUndefined);

        lender.init(_uintFunded);
        principal.init(_uintFunded);
        fixedInterestRate.init(_uintFunded);
        duration.init(_uintFunded);
        borrowerSigned.init(_uintFunded);
        lenderSigned.init(_uintFunded);

        // Set state controlled variable values
        borrower.set(IERC721(_tokenContract).ownerOf(_tokenId), _uintState);
        tokenContract.set(_tokenContract, _uintState);
        tokenId.set(_tokenId, _uintState);

        lender.set(address(0), _uintState);
        principal.set(_principal, _uintState);
        fixedInterestRate.set(_fixedInterestRate, _uintState);
        duration.set(_duration, _uintState);
        borrowerSigned.set(false, _uintState);
        lenderSigned.set(false, _uintState);

        // Set state variables
        priority = _priority;
        state = LoanState.NONLEVERAGED;

        // Set roles
        _setupRole(_ARBITER_ROLE_, address(this));
        _setupRole(_COLLATERAL_APPROVER_ROLE_, address(this));
        _setupRole(_COLLATERAL_APPROVER_ROLE_, _msgSender());
        _setupRole(_COLLATERAL_APPROVER_ROLE_, borrower.get());
        _setupRole(_BORROWER_ROLE_, borrower.get());

        // Sign off borrower
        __sign();
    }

    function setLender() external payable {
        if (hasRole(_BORROWER_ROLE_, _msgSender())) {
            _revokeFunding();
            _revokeRole(_LENDER_ROLE_, lender.get());
            _unsignLender();
        } else {
            _signLender();
            _setupRole(_LENDER_ROLE_, lender.get());
            _depositFunding();
        }
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdraw() external {
        _withdrawFunds(payable(_msgSender()));
    }

    /**
     * @dev Withdraw collateral token.
     *
     */
    function withdrawNft() external onlyRole(_COLLATERAL_OWNER_ROLE_) {
        _unsignBorrower();
        _revokeCollateral();
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawSponsorship() external onlyRole(_LENDER_ROLE_) {
        _revokeFunding();
        _revokeRole(_LENDER_ROLE_, lender.get());
        _unsignLender();
    }

    function sign() external onlyRole(_PARTICIPANT_ROLE_) {
        if (hasRole(_BORROWER_ROLE_, _msgSender())) {
            _signBorrower();
            depositCollateral();
            
            if (state == LoanState.FUNDED) {
                _activateLoan();
            }
        } else {
            _signLender();
        }
    }

    function __sign() private {
        _signBorrower();
    }
}
