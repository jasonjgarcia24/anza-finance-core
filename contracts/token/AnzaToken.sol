// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";

import "../domain/AnzaTokenTransferTypes.sol";

import "./AnzaBaseToken.sol";
import "./AnzaTokenIndexer.sol";

contract AnzaToken is AnzaBaseToken, AnzaTokenIndexer {
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) AnzaBaseToken(_name, _symbol, _baseURI) AnzaTokenAccessController() {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes memory _data
    ) public override onlyRole(_TREASURER_) {
        if (bytes32(_data) == _DEBT_TRANSFER_) {
            __debtTransferFrom(_from, _to, _debtId, _amount, "");
        } else if (bytes32(_data) == _SPONSORSHIP_TRANSFER_) {
            __sponsorshipTransferFrom(_from, _to, _debtId, _amount, "");
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _debtIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override onlyRole(_TREASURER_) {
        if (bytes32(_data) == _DEBT_TRANSFER_) {
            __debtBatchTransferFrom(_from, _to, _debtIds, _amounts, "");
        } else if (bytes32(_data) == _SPONSORSHIP_TRANSFER_) {
            // __sponsorshipBatchTransferFrom(_from, _to, _debtIds, _amounts, "");
        } else {
            revert IllegalTransfer();
        }
    }

    function mint(
        uint256 _debtId,
        uint256 _amount
    ) external onlyRole(_TREASURER_) {
        // Mint ALC debt tokens
        _mint(lenderOf(_debtId), lenderTokenId(_debtId), _amount, "");
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string calldata _collateralURI,
        bytes memory _data
    ) external onlyRole(_LOAN_CONTRACT_) {
        bytes32 _tokenAdminRole = keccak256(_data);

        /** Lender Token */
        if (_id % 2 == 0) {
            // Preset borrower token's URI
            _setURI(_id + 1, _collateralURI);
        }
        /** Borrower Token */
        else {
            _checkRole(_tokenAdminRole, _to);
        }

        // Mint ALC debt tokens
        _mint(_to, _id, _amount, _data);

        // Mint ALC replica token
        _mint(address(bytes20(_data)), _id + 1, 1, "");
    }

    function burn(address _address, uint256 _id, uint256 _amount) external {
        require(
            _address == msg.sender || isApprovedForAll(_address, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(_address, _id, _amount);
    }

    function burnBatch(
        address _address,
        uint256[] memory _ids,
        uint256[] memory _values
    ) public virtual {
        require(
            _address == msg.sender || isApprovedForAll(_address, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(_address, _ids, _values);
    }

    function burnBorrowerToken(
        uint256 _debtId
    ) external onlyRole(_COLLATERAL_VAULT_) {
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

    function _beforeTokenTransfer(
        address,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < _ids.length; ++i) {
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
                // being burned nor minted. Lender token direct transfers are prohibited.
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

                    // Ownership: the replica token's owner shall be set to the zero
                    // address when the borrower withdraws the collateral.
                    _setOwner(_id, address(0));
                }
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
        uint256 _id = borrowerTokenId(_debtId);

        exists(_id)
            ? super._safeTransferFrom(_from, _to, _id, 1, "")
            : _setOwner(_id, _to);
    }

    function __debtBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _debtIds,
        uint256[] memory /* _amounts */,
        bytes memory /* _data */
    ) private {
        uint256[] memory _ids;
        uint256[] memory _amounts;

        for (uint256 i = 0; i < _debtIds.length; ++i) {
            uint256 _id = borrowerTokenId(_debtIds[i]);

            if (!exists(_id)) {
                _ids[i] = _ids[_ids.length - 1];
                delete _ids[_ids.length - 1];
            }
        }

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
        uint256 _id = lenderTokenId(_debtId);
        if (exists(_id)) super.safeTransferFrom(_from, _to, _id, _amount, "");
    }
}
