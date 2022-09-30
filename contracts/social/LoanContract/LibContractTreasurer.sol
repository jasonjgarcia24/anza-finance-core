// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LibContractGlobals as cg } from "./LibContractMaster.sol";
import { StateControlUint, StateControlAddress } from "../../utils/StateControl.sol";

library ERC721Transactions {
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
    function _depositCollateral(
        cg.Participants storage _participants, cg.Global storage _globals
    ) internal {
        IERC721 _erc721 = IERC721(_participants.tokenContract);
        require(
            _erc721.ownerOf(_participants.tokenId) == _participants.borrower,
            "The borrower is not the token owner."
        );
        cg.LoanState _prevState = _globals.state;

        // Transfer ERC721 token to loan contract
        _erc721.safeTransferFrom(
            _participants.borrower, address(this), _participants.tokenId
        );

        // Update loan contract
        IAccessControl ac = IAccessControl(address(this));
        ac.revokeRole(cg._COLLATERAL_OWNER_ROLE_, _globals.factory);
        ac.revokeRole(cg._COLLATERAL_CUSTODIAN_ROLE_, _globals.factory);
        ac.revokeRole(cg._COLLATERAL_CUSTODIAN_ROLE_, _participants.borrower);

        ac.grantRole(cg._COLLATERAL_CUSTODIAN_ROLE_, address(this));

        _globals.state = _globals.state > cg.LoanState.UNSPONSORED
            ? _globals.state
            : cg.LoanState.UNSPONSORED;

        emit cg.LoanStateChanged(_prevState, _globals.state);
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
    function _revokeCollateral(
        cg.Participants storage _participants, cg.Global storage _globals
    ) internal {
        require(isRetainable(_globals), "The loan state must be retainable.");
        cg.LoanState _prevState = _globals.state;

        // Transfer token to borrower
        IERC721(_participants.tokenContract).safeTransferFrom(
            address(this), _participants.borrower, _participants.tokenId
        );

        // Update loan contract
        IAccessControl ac = IAccessControl(address(this));
        ac.revokeRole(cg._COLLATERAL_OWNER_ROLE_, address(this));
        ac.revokeRole(cg._COLLATERAL_CUSTODIAN_ROLE_, address(this));

        ac.grantRole(cg._COLLATERAL_OWNER_ROLE_, _participants.borrower);
        ac.grantRole(cg._COLLATERAL_CUSTODIAN_ROLE_, _participants.borrower);

        _globals.state = cg.LoanState.NONLEVERAGED;

        emit cg.LoanStateChanged(_prevState, _globals.state);
    }
        
    /**
     * @dev The loan contract is considered retainable if the status is inclusively
     * between UNSPONSORED and FUNDED or it is PAID. "Retainable" refers to the
     * borrowe retaining official/sole ownership of the collateralized NFT. 
     *
     * Requirements: NONE
     */
    function isRetainable(cg.Global memory _globals) private pure returns (bool) {
        bool _isPending = _globals.state >= cg.LoanState.UNSPONSORED && _globals.state <= cg.LoanState.FUNDED;
        bool _isPaid = _globals.state == cg.LoanState.PAID;

        return _isPending || _isPaid;
    }
}

library ERC20Transactions {
    using StateControlUint for StateControlUint.Property;
    using StateControlAddress for StateControlAddress.Property;

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
    function _depositFunding(
        cg.Property storage _properties,
        cg.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) internal {
        require(
            msg.sender == _properties.lender.get(),
            "The caller must be the lender."
        );
        require(
            _globals.state == cg.LoanState.SPONSORED,
            "The loan state must be LoanState.SPONSORED."
        );
        cg.LoanState _prevState = _globals.state;

        _accountBalance[_properties.lender.get()] += msg.value;
        require(
            _accountBalance[_properties.lender.get()] >= _properties.principal.get(),
            "The caller's account balance is insufficient."
        );

        // Update loan contract
        _globals.state = cg.LoanState.FUNDED;
        _accountBalance[_properties.lender.get()] += _properties.principal.get();

        emit cg.LoanStateChanged(_prevState, _globals.state);
        emit cg.Deposited(msg.sender, msg.value);
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
    function _revokeFunding(
        cg.Property storage _properties,
        cg.Global storage _globals,
        mapping(address => uint256) storage _accountBalance
    ) internal {
        require(
            _globals.state == cg.LoanState.FUNDED,
            "The loan state must be LoanState.FUNDED."
        );
        cg.LoanState _prevState = _globals.state;

        // Update loan contract
        _globals.state = cg.LoanState.SPONSORED;
        _accountBalance[_properties.lender.get()] += _properties.principal.get();

        emit cg.LoanStateChanged(_prevState, _globals.state);
    }
}
