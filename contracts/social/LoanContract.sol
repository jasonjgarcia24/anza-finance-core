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
        borrower.init(IERC721(_tokenContract).ownerOf(_tokenId), 0);
        tokenContract.init(_tokenContract, 0);
        tokenId.init(_tokenId, 0);

        lender.init(address(0), 4);
        principal.init(_principal, 4);
        fixedInterestRate.init(_fixedInterestRate, 4);
        duration.init(_duration, 4);
        borrowerSigned.init(false, 4);
        lenderSigned.init(false, 4);

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
        _revokeRole(_PARTICIPANT_ROLE_, lender.get());
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
