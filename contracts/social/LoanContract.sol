// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States,
    LibContractInit as Init,
     LibContractUpdate as Update,
    LibContractActivate as Activate
} from "./libraries/LibContractMaster.sol";
import { LibContractNotary as Notary } from "./libraries/LibContractNotary.sol";
import { LibContractScheduler as Scheduler } from "./libraries/LibContractScheduler.sol";
import { ERC721Transactions as ERC721Tx, ERC20Transactions as ERC20Tx } from "./libraries/LibContractTreasurer.sol";

import "../utils/StateControl.sol";
import "../utils/BlockTime.sol";

contract LoanContract is AccessControl, Initializable, Ownable {
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

    /**
     * @dev Emitted when loan contract term(s) are updated.
     */
    event TermsChanged(
        string[] params,
        uint256[] prevValues,
        uint256[] newValues
    );  

    /**
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(States.LoanState indexed prevState, States.LoanState indexed newState);

    /**
     * @dev Emitted when loan contract funding is deposited.
     */
    event Deposited(address indexed payee, uint256 weiAmount);

    /**
     * @dev Emitted when loan contract funding is withdrawn.
     */
    event Withdrawn(address indexed payee, uint256 weiAmount);

    Globals.Participants public loanParticipants;
    Globals.Property public loanProperties;
    Globals.Global public loanGlobals;

    mapping(address => uint256) internal accountBalance;

    function initialize(
        address _loanTreasurer,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) external initializer() {  
        _transferOwnership(_msgSender());

        _setupRole(Globals._ADMIN_ROLE_, address(this));
        _setRoleAdmin(Globals._ADMIN_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._TREASURER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._ARBITER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._BORROWER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._LENDER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._PARTICIPANT_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._COLLATERAL_CUSTODIAN_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._COLLATERAL_OWNER_ROLE_, Globals._ADMIN_ROLE_);

        _setupRole(Globals._TREASURER_ROLE_, _loanTreasurer);

        // Initialize state controlled variables
        Init.initializeContract_(
            loanParticipants,
            loanProperties,
            loanGlobals,
            _loanTreasurer,
            _tokenContract,
            _tokenId,
            _priority,
            _principal,
            _fixedInterestRate,
            _duration
        );

        // // Sign off borrower
        __sign();
    }

    function updateTerms(string[] memory _params, uint256[] memory _newValues)
        external
        onlyRole(Globals._BORROWER_ROLE_)
    {
        if (loanProperties.lenderSigned.get()) {
            Notary._unsignLender(loanProperties, loanGlobals);
        }

        Update._updateTerms(loanProperties, loanGlobals, _params, _newValues);
    }

    function depositCollateral() external payable onlyRole(Globals._COLLATERAL_OWNER_ROLE_) {
        ERC721Tx.depositCollateral_(loanParticipants, loanGlobals);
    }

    function setLender() external payable {
        if (hasRole(Globals._BORROWER_ROLE_, _msgSender())) {
            ERC20Tx.revokeFunding_(loanProperties, loanGlobals, accountBalance);
            _revokeRole(Globals._LENDER_ROLE_, loanProperties.lender.get());
            Notary._unsignLender(loanProperties, loanGlobals);
        } else {
            Notary.signLender_(loanProperties, loanGlobals, accountBalance);
            _setupRole(Globals._LENDER_ROLE_, loanProperties.lender.get());
            ERC20Tx.depositFunding_(loanProperties, loanGlobals, accountBalance);

            if (loanProperties.borrowerSigned.get()) {
                __activate();
            }
        }
    }

    function makePayment() external payable onlyRole(Globals._BORROWER_ROLE_) {
            ERC20Tx.depositPayment_(loanParticipants, loanProperties, loanGlobals, accountBalance);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawFunds() external {
        if (loanGlobals.state <= States.LoanState.FUNDED) {
            _checkRole(Globals._LENDER_ROLE_);
        }

        ERC20Tx.withdrawFunds_(payable(_msgSender()), accountBalance);
    }

    /**
     * @dev Withdraw collateral token.
     *
     */
    function withdrawNft() external onlyRole(Globals._COLLATERAL_OWNER_ROLE_) {
        Notary.unsignBorrower_(loanProperties, loanGlobals);
        ERC721Tx.revokeCollateral_(loanParticipants, loanGlobals);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawSponsorship() external onlyRole(Globals._LENDER_ROLE_) {
        ERC20Tx.revokeFunding_(loanProperties, loanGlobals, accountBalance);
        _revokeRole(Globals._LENDER_ROLE_, loanProperties.lender.get());
        _revokeRole(Globals._PARTICIPANT_ROLE_, loanProperties.lender.get());
        Notary._unsignLender(loanProperties, loanGlobals);
    }

    function sign() external onlyRole(Globals._PARTICIPANT_ROLE_) {
        if (hasRole(Globals._BORROWER_ROLE_, _msgSender())) {
            Notary.signBorrower_(loanParticipants, loanProperties, loanGlobals);
            ERC721Tx.depositCollateral_(loanParticipants, loanGlobals);

            if (loanProperties.lenderSigned.get()) {
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
    function close() external onlyRole(Globals._COLLATERAL_OWNER_ROLE_) {
        ERC721Tx.revokeCollateral_(loanParticipants, loanGlobals);
        
        // Clear loan contract approval
        IERC721(loanParticipants.tokenContract).approve(address(0), loanParticipants.tokenId);
        loanGlobals.state = States.LoanState.CLOSED;
    }

    function __sign() private {
        Notary.signBorrower_(loanParticipants, loanProperties, loanGlobals);
    }

    function __activate() private {
        loanProperties.stopBlockstamp.onlyState(loanGlobals.state);

        Scheduler.initSchedule_(loanProperties, loanGlobals);
        Activate.activateLoan_(loanParticipants, loanProperties, loanGlobals, accountBalance);

        emit LoanActivated(
            address(this),
            loanParticipants.borrower,
            loanProperties.lender.get(),
            loanParticipants.tokenContract,
            loanParticipants.tokenId,
            uint256(loanGlobals.state)
        );
    }
    
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
