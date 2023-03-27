// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanTreasurey.sol";
import "./interfaces/IAnzaDebtToken.sol";

import {LibContractGlobals as Globals, LibContractStates as States, LibContractInit as Init, LibContractAssess as Assess, LibContractUpdate as Update, LibContractActivate as Activate} from "./libraries/LibContractMaster.sol";
import {LibContractNotary as Notary} from "./libraries/LibContractNotary.sol";
import {LibContractScheduler as Scheduler} from "./libraries/LibContractScheduler.sol";
import {LibLoanTreasurey as Treasurey, ERC721Transactions as ERC721Tx, ERC20Transactions as ERC20Tx, TreasurerUtils} from "./libraries/LibContractTreasurer.sol";
import {LibContractCollector as Collector} from "./libraries/LibContractCollections.sol";

import "../utils/StateControl.sol";
import "../utils/BlockTime.sol";
import "hardhat/console.sol";

contract LoanContract is AccessControl, Initializable, ERC1155Holder {
    using StateControlUint256 for StateControlUint256.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

    Globals.Participants public loanParticipants;
    Globals.Property public loanProperties;
    Globals.Global public loanGlobals;

    mapping(address => uint256) internal accountBalance;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return (interfaceId == type(ILoanContract).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function initialize(
        address _loanTreasurer,
        address _loanCollector,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _debtId,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) external initializer {
        _setRoleAdmin(Globals._ADMIN_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._TREASURER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._COLLECTOR_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._ARBITER_ROLE_, Globals._ADMIN_ROLE_);

        _setRoleAdmin(Globals._BORROWER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._LENDER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._PARTICIPANT_ROLE_, Globals._ADMIN_ROLE_);

        _setRoleAdmin(Globals._COLLATERAL_OWNER_ROLE_, Globals._ADMIN_ROLE_);
        _setRoleAdmin(Globals._COLLATERAL_APPROVER_ROLE_, Globals._ADMIN_ROLE_);

        _setupRole(Globals._ADMIN_ROLE_, address(this));
        _setupRole(Globals._TREASURER_ROLE_, _loanTreasurer);
        _setupRole(Globals._COLLECTOR_ROLE_, _loanCollector);

        // Initialize state controlled variables
        Init.initializeContract_(
            loanParticipants,
            loanProperties,
            loanGlobals,
            _loanTreasurer,
            _loanCollector,
            _tokenContract,
            _tokenId,
            _debtId,
            _principal,
            _fixedInterestRate,
            _duration
        );

        // Sign off borrower
        __sign();
    }

    function updateTerms(
        string[] calldata _params,
        uint256[] calldata _newValues
    ) external onlyRole(Globals._BORROWER_ROLE_) {
        if (loanProperties.lenderSigned.get()) {
            Notary._unsignLender(loanProperties, loanGlobals);
        }

        Update.updateTerms_(loanProperties, loanGlobals, _params, _newValues);
    }

    function depositCollateral()
        external
        payable
        onlyRole(Globals._COLLATERAL_APPROVER_ROLE_)
    {
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
            ERC20Tx.depositFunding_(
                loanProperties,
                loanGlobals,
                accountBalance
            );

            if (loanProperties.borrowerSigned.get()) {
                __activate();
            }
        }
    }

    function makePayment() external payable onlyRole(Globals._TREASURER_ROLE_) {
        __updateBalance();
        ERC20Tx.depositPayment_(
            loanParticipants,
            loanProperties,
            loanGlobals,
            accountBalance
        );
    }

    /**
     * @dev See {LibContractTreasurer:ERC20Transactions-withdrawFunds_}
     *
     * Requirements:
     *
     * - Only the treasurer is allowed to direct funds withdrawal.
     */
    function withdrawFunds(address _payee)
        external
        onlyRole(Globals._TREASURER_ROLE_)
    {
        require(_msgSender() != _payee, "Caller cannot be withdrawer.");
        ERC20Tx.withdrawFunds_(payable(_payee), accountBalance);
    }

    /**
     * @dev Withdraw collateral token.
     *
     */
    function withdrawNft()
        external
        onlyRole(Globals._COLLATERAL_APPROVER_ROLE_)
    {
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

    function getBalance() external view returns (uint256) {
        return
            msg.sender == loanParticipants.treasurey
                ? Treasurey.getBalance_(loanProperties, loanGlobals)
                : accountBalance[msg.sender];
    }

    function updateBalance() external onlyRole(Globals._TREASURER_ROLE_) {
        __updateBalance();
    }

    /**
     * @dev Revoke collateralized token and revoke LoanContract approval. This
     * effectively renders the LoanContract closed.
     *
     * Requirements:
     *
     * - The caller must have been granted the _COLLATERAL_APPROVER_ROLE_.
     */
    function close() external onlyRole(Globals._ADMIN_ROLE_) {
        ERC721Tx.revokeCollateral_(loanParticipants, loanGlobals);

        // Clear loan contract approval
        IERC721(loanParticipants.tokenContract).approve(
            address(0),
            loanParticipants.tokenId
        );
        loanGlobals.state = States.LoanState.CLOSED;
    }

    /**
     * @dev See {LibContractCollections:LibContractCollector-defaultContract_}
     *
     * Requirements:
     *
     * - Only the treasurer can call this function.
     */
    function initDefault() external onlyRole(Globals._TREASURER_ROLE_) {
        Collector.defaultContract_(loanParticipants, loanGlobals);
    }

    /**
     * @dev See {LibContractNotary:LibContractNotary-signBorrower_}.
     */
    function __sign() private {
        Notary.signBorrower_(loanParticipants, loanProperties, loanGlobals);
    }

    /**
     * @dev See {LibContractMaster:LibContractActivate-activateLoan_s}
     */
    function __activate() private {
        Activate.activateLoan_(
            loanParticipants,
            loanProperties,
            loanGlobals,
            accountBalance
        );
    }

    function __updateBalance() private {
        Treasurey.updateBalance_(loanProperties, loanGlobals);
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
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

    // /**
    //  * @dev Whenever an {IERC1155} `tokenId` token is transferred to this contract via {IERC1155-safeTransferFrom}
    //  * by `operator` from `from`, this function is called.
    //  *
    //  * It must return its Solidity selector to confirm the token transfer.
    //  * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
    //  */
    // function onERC1155Received(
    //     address,
    //     address,
    //     uint256,
    //     uint256,
    //     bytes calldata
    // ) external pure returns (bytes4) {
    //     return
    //         bytes4(
    //             keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
    //         );
    // }

    fallback() external {}
}
