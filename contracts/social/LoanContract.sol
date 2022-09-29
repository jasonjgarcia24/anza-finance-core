// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./LoanContract/AContractManager.sol";

contract LoanContract is Initializable, Ownable, AContractManager {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

    /**
     * @dev Emitted when loan contract term(s) are updated.
     */
    event LoanActivated(
        address indexed loanContract,
        address indexed borrower,
        address indexed lender,
        address tokenContract,
        uint256 tokenId,
        uint256 state
    );

    function initialize(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) external initializer() {  
        _transferOwnership(_msgSender());

        // Initialize state controlled variables
        borrower = IERC721(_tokenContract).ownerOf(_tokenId);
        tokenContract = _tokenContract;
        tokenId = _tokenId;

        uint256 _fundedState = uint256(LoanState.FUNDED);
        lender.init(address(0), _fundedState);
        principal.init(_principal, _fundedState);
        fixedInterestRate.init(_fixedInterestRate, _fundedState);
        duration.init(_duration.daysToBlocks(), _fundedState);
        borrowerSigned.init(false, _fundedState);
        lenderSigned.init(false, _fundedState);

        balance.init(0, uint256(LoanState.PAID));
        stopBlockstamp.init(type(uint256).max, _fundedState);

        // Set state variables
        factory = _msgSender();
        priority = _priority;
        state = LoanState.NONLEVERAGED;

        // Set roles
        _setupRole(_ADMIN_ROLE_, _msgSender());
        _setupRole(_ARBITER_ROLE_, address(this));
        _setupRole(_BORROWER_ROLE_, borrower);
        _setupRole(_COLLATERAL_OWNER_ROLE_, factory);
        _setupRole(_COLLATERAL_OWNER_ROLE_, borrower);
        _setupRole(_COLLATERAL_CUSTODIAN_ROLE_, factory);
        _setupRole(_COLLATERAL_CUSTODIAN_ROLE_, borrower);

        // Sign off borrower
        __sign();
    }

    function setLender() external payable {
        if (_hasRole(_BORROWER_ROLE_)) {
            _revokeFunding();
            _revokeRole(_LENDER_ROLE_, lender.get());
            _unsignLender();
        } else {
            _signLender();
            _setupRole(_LENDER_ROLE_, lender.get());
            _depositFunding();

            if (borrowerSigned.get()) {
                __activate();
            }
        }
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawFunds() external {
        if (state <= LoanState.FUNDED) {
            _checkRole(_LENDER_ROLE_);
            _withdrawFunds(payable(_msgSender()));
        } else {
            _withdrawFunds(payable(_msgSender()));
        }
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
        if (_hasRole(_BORROWER_ROLE_)) {
            _signBorrower();
            depositCollateral();

            if (lenderSigned.get()) {
                __activate();
            }
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
        IERC721(tokenContract).approve(address(0), tokenId);
        state = LoanState.CLOSED;
    }

    function __sign() private {
        _signBorrower();
    }

    function __activate() private {
        stopBlockstamp.onlyState(uint256(state));

        _initSchedule();
        _activateLoan();

        emit LoanActivated(
            address(this),
            borrower,
            lender.get(),
            tokenContract,
            tokenId,
            uint256(state)
        );
    }
}
