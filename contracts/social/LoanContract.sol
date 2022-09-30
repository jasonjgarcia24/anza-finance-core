// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { LibContractGlobals as cg, LibContractInit as ci, LibContractActivate as ca } from "./LoanContract/LibContractMaster.sol";
import { LibContractNotary as cn } from "./LoanContract/LibContractNotary.sol";
import { LibContractScheduler as cs } from "./LoanContract/LibContractScheduler.sol";
import { ERC721Transactions as ERC721Tx, ERC20Transactions as ERC20Tx } from "./LoanContract/LibContractTreasurer.sol";

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
     * @dev Emitted when a loan contract state is changed.
     */
    event LoanStateChanged(cg.LoanState indexed prevState, cg.LoanState indexed newState);

    /**
     * @dev Emitted when loan contract funding is deposited.
     */
    event Deposited(address indexed payee, uint256 weiAmount);

    /**
     * @dev Emitted when loan contract funding is withdrawn.
     */
    event Withdrawn(address indexed payee, uint256 weiAmount);

    cg.Participants public loanParticipants;
    cg.Property public loanProperties;
    cg.Global public loanGlobals;

    mapping(address => uint256) internal accountBalance;

    function initialize(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) external initializer() {  
        _transferOwnership(_msgSender());

        _setupRole(cg._ADMIN_ROLE_, address(this));
        _setRoleAdmin(cg._ADMIN_ROLE_, cg._ADMIN_ROLE_);
        _setRoleAdmin(cg._ARBITER_ROLE_, cg._ADMIN_ROLE_);
        _setRoleAdmin(cg._BORROWER_ROLE_, cg._ADMIN_ROLE_);
        _setRoleAdmin(cg._LENDER_ROLE_, cg._ADMIN_ROLE_);
        _setRoleAdmin(cg._PARTICIPANT_ROLE_, cg._ADMIN_ROLE_);
        _setRoleAdmin(cg._COLLATERAL_CUSTODIAN_ROLE_, cg._ADMIN_ROLE_);
        _setRoleAdmin(cg._COLLATERAL_OWNER_ROLE_, cg._ADMIN_ROLE_);

        // Initialize state controlled variables
        ci._initializeContract(
            loanParticipants,
            loanProperties,
            loanGlobals,
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

    function depositCollateral() external payable onlyRole(cg._COLLATERAL_OWNER_ROLE_) {
        ERC721Tx._depositCollateral(loanParticipants, loanGlobals);
    }

    function setLender() external payable {
        if (hasRole(cg._BORROWER_ROLE_, _msgSender())) {
            ERC20Tx._revokeFunding(loanProperties, loanGlobals, accountBalance);
            _revokeRole(cg._LENDER_ROLE_, loanProperties.lender.get());
            cn._unsignLender(loanProperties, loanGlobals);
        } else {
            cn._signLender(loanProperties, loanGlobals, accountBalance);
            _setupRole(cg._LENDER_ROLE_, loanProperties.lender.get());
            ERC20Tx._depositFunding(loanProperties, loanGlobals, accountBalance);

            if (loanProperties.borrowerSigned.get()) {
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
        if (loanGlobals.state <= cg.LoanState.FUNDED) {
            _checkRole(cg._LENDER_ROLE_);
        }

        ERC20Tx._withdrawFunds(payable(_msgSender()), accountBalance);
    }

    /**
     * @dev Withdraw collateral token.
     *
     */
    function withdrawNft() external onlyRole(cg._COLLATERAL_OWNER_ROLE_) {
        cn._unsignBorrower(loanProperties, loanGlobals);
        ERC721Tx._revokeCollateral(loanParticipants, loanGlobals);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawSponsorship() external onlyRole(cg._LENDER_ROLE_) {
        ERC20Tx._revokeFunding(loanProperties, loanGlobals, accountBalance);
        _revokeRole(cg._LENDER_ROLE_, loanProperties.lender.get());
        _revokeRole(cg._PARTICIPANT_ROLE_, loanProperties.lender.get());
        cn._unsignLender(loanProperties, loanGlobals);
    }

    function sign() external onlyRole(cg._PARTICIPANT_ROLE_) {
        if (hasRole(cg._BORROWER_ROLE_, _msgSender())) {
            cn._signBorrower(loanParticipants, loanProperties, loanGlobals);
            ERC721Tx._depositCollateral(loanParticipants, loanGlobals);

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
    function close() external onlyRole(cg._COLLATERAL_OWNER_ROLE_) {
        ERC721Tx._revokeCollateral(loanParticipants, loanGlobals);
        
        // Clear loan contract approval
        IERC721(loanParticipants.tokenContract).approve(address(0), loanParticipants.tokenId);
        loanGlobals.state = cg.LoanState.CLOSED;
    }

    function __sign() private {
        cn._signBorrower(loanParticipants, loanProperties, loanGlobals);
    }

    function __activate() private {
        loanProperties.stopBlockstamp.onlyState(uint256(loanGlobals.state));

        cs._initSchedule(loanProperties, loanGlobals);
        ca._activateLoan(loanParticipants, loanProperties, loanGlobals, accountBalance);

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
