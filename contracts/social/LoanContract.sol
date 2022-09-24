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
        // Initialize state controlled variables
        borrower_.init(IERC721(_tokenContract).ownerOf(_tokenId), 0);
        tokenContract_.init(_tokenContract, 0);
        tokenId_.init(_tokenId, 0);

        lender_.init(address(0), 4);
        principal_.init(_principal, 4);
        fixedInterestRate_.init(_fixedInterestRate, 4);
        duration_.init(_duration, 4);
        borrowerSigned_.init(false, 4);
        lenderSigned_.init(false, 4);

        // Set state variables
        factory = _msgSender();
        priority = _priority;
        state = LoanState.NONLEVERAGED;

        // Set roles
        _setupRole(_ARBITER_ROLE_, address(this));
        _setupRole(_BORROWER_ROLE_, borrower_.get());
        _setupRole(_COLLATERAL_OWNER_ROLE_, factory);
        _setupRole(_COLLATERAL_OWNER_ROLE_, borrower_.get());
        _setupRole(_COLLATERAL_CUSTODIAN_ROLE_, factory);
        _setupRole(_COLLATERAL_CUSTODIAN_ROLE_, borrower_.get());

        // Sign off borrower
        __sign();
    }

    function setLender() external payable {
        if (_hasRole(_BORROWER_ROLE_)) {
            _revokeFunding();
            _revokeRole(_LENDER_ROLE_, lender_.get());
            _unsignLender();
        } else {
            _signLender();
            _setupRole(_LENDER_ROLE_, lender_.get());
            _depositFunding();
        }
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawFunds() external {
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
        _revokeRole(_LENDER_ROLE_, lender_.get());
        _revokeRole(_PARTICIPANT_ROLE_, lender_.get());
        _unsignLender();
    }

    function sign() external onlyRole(_PARTICIPANT_ROLE_) {
        if (_hasRole(_BORROWER_ROLE_)) {
            _signBorrower();
            depositCollateral();
        }
    }

    /**
     * @dev Revoke collateralized token and revoke LoanContract approval. This
     * effectively renders the LoanContract closed.
     *
     * Requirements:
     *
     * - The caller must have been granted the _COLLATERAL_OWNER_ROLE_.
     *
     */
    function close() external onlyRole(_COLLATERAL_OWNER_ROLE_) {
        _revokeCollateral();
        
        // Clear loan contract approval
        IERC721(tokenContract_.get()).approve(address(0), tokenId_.get());
        state = LoanState.CLOSED;
    }

    function __sign() private {
        _signBorrower();
    }
}
