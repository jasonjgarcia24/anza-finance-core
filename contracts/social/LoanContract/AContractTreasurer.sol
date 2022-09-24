// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./AContractGlobals.sol";

abstract contract AContractTreasurer is AContractGlobals {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using Address for address payable;

    /**
     * @dev Emitted when loan contract funding is deposited.
     */
    event Deposited(address indexed payee, uint256 weiAmount);

    /**
     * @dev Emitted when loan contract funding is withdrawn.
     */
    event Withdrawn(address indexed payee, uint256 weiAmount);

    /**
     * @dev The contract should be able to receive Eth.
     * 
     * Emits {Deposited} event.
     */
    receive() external payable onlyRole(_PARTICIPANT_ROLE_) {        
        payable(address(this)).transfer(msg.value);

        emit Deposited(_msgSender(), msg.value);
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

    /**
     * @dev Transfers owners of the collateral to the loan contract.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_BORROWER_ROLE_`.
     * - The loan contract state must be `LoanState.NONLEVERAGED`.
     *
     * Emits {LoanStateChanged} event.
     */
    function depositCollateral() public onlyRole(_COLLATERAL_OWNER_ROLE_) {
        require(
            state == LoanState.NONLEVERAGED,
            "The loan state must be LoanState.NONLEVERAGED."
        );
        LoanState _prevState = state;

        // Transfer ERC721 token to loan contract
        IERC721(tokenContract_.get()).safeTransferFrom(borrower_.get(), address(this), tokenId_.get());

        // Update loan contract
        _revokeRole(_COLLATERAL_OWNER_ROLE_, borrower_.get());
        _revokeRole(_COLLATERAL_CUSTODIAN_ROLE_, factory);
        _revokeRole(_COLLATERAL_CUSTODIAN_ROLE_, borrower_.get());

        _setupRole(_COLLATERAL_OWNER_ROLE_, address(this));
        _setupRole(_COLLATERAL_CUSTODIAN_ROLE_, address(this));

        state = state > LoanState.UNSPONSORED ? state : LoanState.UNSPONSORED;

        emit LoanStateChanged(_prevState, state);
    }

    /**
     * @dev Transfers ownership of the collateral to the borrower.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_COLLATERAL_OWNER_ROLE_` (handled in the
     *   calling function).
     * - The loan contract must be retainable.
     *
     * Emits {LoanStateChanged} event.
     */
    function _revokeCollateral() internal {
        require(isRetainable(), "The loan state must be retainable.");
        LoanState _prevState = state;

        // Transfer token to borrower
        IERC721(tokenContract_.get()).safeTransferFrom(address(this), borrower_.get(), tokenId_.get());
        // IERC721(tokenContract_.get()).approve(address(this), true);

        // Update loan contract
        _revokeRole(_COLLATERAL_OWNER_ROLE_, address(this));
        _revokeRole(_COLLATERAL_CUSTODIAN_ROLE_, address(this));

        _setupRole(_COLLATERAL_OWNER_ROLE_, borrower_.get());
        _setupRole(_COLLATERAL_CUSTODIAN_ROLE_, borrower_.get());

        state = LoanState.CLOSED;

        emit LoanStateChanged(_prevState, state);
    }

    /**
     * @dev Funds the loan contract.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_LENDER_ROLE_`.
     * - The loan contract state must be `LoanState.SPONSORED`.
     *
     * Emits {LoanStateChanged} and {Deposited} events.
     */
    function _depositFunding() public payable onlyRole(_LENDER_ROLE_) {
        require(
            _msgSender() == lender_.get(),
            "The caller must be the lender."
        );
        require(
            state == LoanState.SPONSORED,
            "The loan state must be LoanState.SPONSORED."
        );
        LoanState _prevState = state;

        accountBalance[lender_.get()] += msg.value;
        require(
            accountBalance[lender_.get()] >= principal_.get(),
            "The caller's account balance is insufficient."
        );

        // Update loan contract
        state = LoanState.FUNDED;
        accountBalance[lender_.get()] -= principal_.get();

        emit LoanStateChanged(_prevState, state);
        emit Deposited(_msgSender(), msg.value);
    }
    
    /**
     * @dev Defunds the loan contract.
     *
     * Requirements:
     *
     * - The loan contract state must be LoanState.FUNDED.
     *
     * Emits {LoanStateChanged} event.
     */
    function _revokeFunding() internal {
        require(
            state == LoanState.FUNDED,
            "The loan state must be LoanState.FUNDED."
        );
        LoanState _prevState = state;

        // Update loan contract
        state = LoanState.SPONSORED;
        accountBalance[lender_.get()] += principal_.get();

        emit LoanStateChanged(_prevState, state);
    }

    /**
     * @dev Withdraws funds from loan.
     * @param _payee The address whose funds will be withdrawn and transferred to.
     * 
     * Requirements: NONE
     * 
     * Emits a {Withdrawn} event.
     */
    function _withdrawFunds(address payable _payee) internal {     
        uint256 _payment = accountBalance[_payee];
        accountBalance[_payee] = 0;

        _payee.sendValue(_payment);

        emit Withdrawn(_payee, _payment);
    }
}