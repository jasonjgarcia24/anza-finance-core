// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@tokens-constants/AnzaTokenTransferTypes.sol";
import {_LOAN_CONTRACT_, _TREASURER_, _COLLATERAL_VAULT_} from "@lending-constants/LoanContractRoles.sol";
import {StdAnzaTokenErrors} from "@custom-errors/StdAnzaTokenErrors.sol";

import {IAnzaTokenLite} from "@tokens-interfaces/IAnzaToken.sol";
import {AnzaBaseToken} from "./AnzaBaseToken.sol";
import {AnzaTokenCatalog} from "./AnzaTokenCatalog.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

contract AnzaToken is IAnzaTokenLite, AnzaBaseToken, AnzaTokenCatalog {
    using AnzaTokenIndexer for uint256;

    constructor(
        string memory _baseURI
    ) AnzaBaseToken("Anza Debt Token", "ADT", _baseURI) {}

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(AnzaBaseToken, AnzaTokenCatalog)
        returns (bool)
    {
        return
            _interfaceId == type(IAnzaTokenLite).interfaceId ||
            AnzaBaseToken.supportsInterface(_interfaceId) ||
            AnzaTokenCatalog.supportsInterface(_interfaceId);
    }

    modifier onlyValidMint(uint256 _amount) {
        if (_amount == 0) revert StdAnzaTokenErrors.IllegalMint();
        _;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes memory _data
    ) public override {
        if (hasRole(_TREASURER_, _msgSender())) {
            if (bytes32(_data) == _DEBT_TRANSFER_) {
                __debtTransferFrom(_from, _to, _debtId, _amount, "");
            } else if (bytes32(_data) == _SPONSORSHIP_TRANSFER_) {
                __sponsorshipTransferFrom(_from, _to, _debtId, _amount, "");
            }
        } else {
            super.safeTransferFrom(_from, _to, _debtId, _amount, _data);
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override {
        // Debt transfers are only allowed by the treasurer
        if (bytes32(_data) == _DEBT_TRANSFER_) {
            _checkRole(_TREASURER_, _msgSender());

            super._safeBatchTransferFrom(_from, _to, _ids, _amounts, "");
        }
        // Sponsorship batch transfers are allowed by owners and approved as
        // allowed in the ERC1155 standard
        else if (bytes32(_data) == _SPONSORSHIP_TRANSFER_) {
            super.safeBatchTransferFrom(_from, _to, _ids, _amounts, "");
        }
        // Disallow all batch transfers that do not specify the transfer type
        // as either debt or sponsorship within the `data` field
        else {
            revert StdAnzaTokenErrors.IllegalTransfer();
        }
    }

    /**
     * Mint ADT pair for a given issued debt's lender and borrower.
     *
     * This function is for initial loan contract creation with a borrower's
     * collateral.
     *
     * @param _lender The address of the debt's lender.
     * @param _borrower The address of the debt's borrower.
     * @param _debtId The ID of the debt.
     * @param _amount The amount of ADT to mint for the lender.
     * @param _collateralURI The URI of the collateral NFT. This will be
     * used to set the URI of the borrower's ADT URI.
     *
     * @dev This function is only callable by the loan contract.
     */
    function mintPair(
        address _lender,
        address _borrower,
        uint256 _debtId,
        uint256 _amount,
        bytes calldata _collateralURI
    ) external onlyRole(_LOAN_CONTRACT_) {
        // Mint ADT for lender
        _mint(_lender, _debtId.debtIdToLenderTokenId(), _amount);

        // Mint ADT for borrower
        _mint(_borrower, _debtId.debtIdToBorrowerTokenId(), 1, _collateralURI);
    }

    function mint(
        uint256 _debtId,
        uint256 _amount
    ) external onlyRole(_TREASURER_) {
        console.log("minting debtId: %s", _debtId);
        console.log("minting amount: %s", _amount);

        // Mint ADT for lender
        _mint(lenderOf(_debtId), _debtId.debtIdToLenderTokenId(), _amount);
    }

    function burnBorrowerToken(uint256 _debtId) external onlyRole(_TREASURER_) {
        // uint256 _borrowerTokenId = borrowerTokenId(_debtId);

        _burn(borrowerOf(_debtId), _debtId.debtIdToBorrowerTokenId(), 1);
    }

    function burnLenderToken(
        uint256 _debtId,
        uint256 _amount
    ) external onlyRole(_TREASURER_) {
        _burn(lenderOf(_debtId), _debtId.debtIdToLenderTokenId(), _amount);
    }

    /**
     * Internal mint for ADT lender tokens.
     *
     * @notice This function is only for minting lender tokens.
     *
     * @param _to The address to mint the tokens to.
     * @param _id The ID of the token to mint.
     * @param _amount The amount of tokens to mint.
     *
     * @dev This function allows only valid mint amounts.
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal onlyValidMint(_amount) {
        super._mint(_to, _id, _amount, "");
    }

    /**
     * Internal mint for ADT borrower tokens.
     *
     * @notice This function is only for minting borrower tokens.
     *
     * @param _to The address to mint the tokens to.
     * @param _id The ID of the token to mint.
     * @param _amount The amount of tokens to mint.
     * @param _data The URI of the token to mint.
     *
     * @dev This function allows only valid mint amounts.
     * @dev This function sets the URI of the token.
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal override onlyValidMint(_amount) {
        super._mint(_to, _id, _amount, _data);
        _setURI(_id, string(_data));
    }

    function _beforeTokenTransfer(
        address,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory /* _data */
    ) internal virtual override {
        for (uint256 i; i < _ids.length; ) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];

            /** Minting */
            if (_from == address(0)) {
                // Total Supply: increment the total supply of the token ID if the
                // token is being minted.
                _incrementTotalSupply(_id, _amount);

                // Ownership: set the token owner.
                _setOwner(_id, _to);
            }
            /** Transfering */
            else if (_to != address(0)) {
                // Total Supply: the total supply shall not be updated when the
                // tokens are being transfered to a non-zero address while not a
                // minting transaction.

                // Ownership: set token owners only when the replica token is not
                // being burned nor minted. Direct lender token transfers are prohibited.
                if (_id % 2 == 0) revert StdAnzaTokenErrors.IllegalTransfer();
                _setOwner(_id, _to);
            }
            /** Burning */
            else {
                if (_id % 2 == 0) {
                    // Total Supply: decrement the total supply of the token ID if
                    // the token is being burned.
                    _decrementTotalSupply(_id, _amount);

                    // Ownership: set the lender token owner to the zero address when
                    // the debt balance is zero.
                    if (totalSupply(_id) == 0) _setOwner(_id, address(0));
                } else {
                    // Do not allow burning of replica token if the current debt balance
                    // is not zero.
                    if (totalSupply(_id - 1) != 0)
                        revert StdAnzaTokenErrors.IllegalTransfer();

                    // Total Supply: decrement the total supply of the borrower token
                    // ID by 1 to account for the replica token.
                    _decrementTotalSupply(_id, 1);

                    // // Ownership: the replica token's owner shall be set to the zero
                    // // address when the borrower withdraws the collateral.
                    // _setOwner(_id, address(0));
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function __debtTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        uint256 /* _amount */,
        bytes memory /* _data */
    ) private {
        super._safeTransferFrom(
            _from,
            _to,
            _debtId.debtIdToBorrowerTokenId(),
            1,
            ""
        );
    }

    function __debtBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory /* _data */
    ) private {
        if (_ids.length > 0)
            super.safeBatchTransferFrom(_from, _to, _ids, _amounts, "");
    }

    function __sponsorshipTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes memory /* _data */
    ) private {
        super._safeTransferFrom(
            _from,
            _to,
            _debtId.debtIdToLenderTokenId(),
            _amount,
            ""
        );
    }
}
