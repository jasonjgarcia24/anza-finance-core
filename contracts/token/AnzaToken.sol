// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../../lib/forge-std/src/console.sol";

import "../domain/AnzaTokenTransferTypes.sol";

import {IAnzaTokenLite} from "../interfaces/IAnzaTokenLite.sol";
import {AnzaBaseToken, _LOAN_CONTRACT_, _TREASURER_, _COLLATERAL_VAULT_} from "./AnzaBaseToken.sol";
import {AnzaTokenIndexer} from "./AnzaTokenIndexer.sol";

contract AnzaToken is IAnzaTokenLite, AnzaBaseToken, AnzaTokenIndexer {
    constructor(
        string memory _baseURI
    ) AnzaBaseToken("Anza Debt Token", "ADT", _baseURI) {}

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(AnzaBaseToken, AnzaTokenIndexer)
        returns (bool)
    {
        return
            _interfaceId == type(IAnzaTokenLite).interfaceId ||
            AnzaBaseToken.supportsInterface(_interfaceId) ||
            AnzaTokenIndexer.supportsInterface(_interfaceId);
    }

    modifier onlyValidMint(uint256 _amount) {
        if (_amount == 0) revert IllegalMint();
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
            revert IllegalTransfer();
        }
    }

    function mint(
        uint256 _debtId,
        uint256 _amount
    ) external onlyRole(_TREASURER_) {
        // Mint ADT for lender
        _mint(lenderOf(_debtId), lenderTokenId(_debtId), _amount, "");
    }

    function mint(
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes memory _data
    ) external onlyRole(_LOAN_CONTRACT_) {
        // Mint ADT for lender
        _mint(_to, lenderTokenId(_debtId), _amount, "");

        // Mint ADT for borrower
        (address _borrower, uint256 _rootDebtId) = abi.decode(
            _data,
            (address, uint256)
        );
        _mint(_borrower, borrowerTokenId(_debtId), 1, "");
        _setURI(borrowerTokenId(_debtId), uri(borrowerTokenId(_rootDebtId)));
    }

    function mint(
        address _to,
        uint256 _debtId,
        uint256 _amount,
        string calldata _collateralURI,
        bytes memory _data
    ) external onlyRole(_LOAN_CONTRACT_) {
        // Mint ADT for lender
        _mint(_to, lenderTokenId(_debtId), _amount, "");

        // Mint ADT for borrower
        _mint(address(bytes20(_data)), borrowerTokenId(_debtId), 1, "");
        _setURI(borrowerTokenId(_debtId), _collateralURI);
    }

    function burnBorrowerToken(uint256 _debtId) external onlyRole(_TREASURER_) {
        uint256 _borrowerTokenId = borrowerTokenId(_debtId);

        _burn(borrowerOf(_debtId), _borrowerTokenId, 1);
    }

    function burnLenderToken(
        uint256 _debtId,
        uint256 _amount
    ) external onlyRole(_TREASURER_) {
        uint256 _lenderTokenId = lenderTokenId(_debtId);

        _burn(lenderOf(_debtId), _lenderTokenId, _amount);
    }

    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal override onlyValidMint(_amount) {
        super._mint(_to, _id, _amount, _data);
    }

    function _beforeTokenTransfer(
        address,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory /* _data */
    ) internal virtual override {
        for (uint256 i = 0; i < _ids.length; ) {
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
                if (_id % 2 == 0) revert IllegalTransfer();
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
                    if (totalSupply(_id - 1) != 0) revert IllegalTransfer();

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
        super._safeTransferFrom(_from, _to, borrowerTokenId(_debtId), 1, "");
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
            lenderTokenId(_debtId),
            _amount,
            ""
        );
    }
}
