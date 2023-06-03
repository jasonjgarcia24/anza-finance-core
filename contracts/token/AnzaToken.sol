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
            revert InvalidTransferType();
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

        /* Lender Token */
        if (_id % 2 == 0) {
            // Update borrower token admin
            __updateBorrowerRole(address(0), address(bytes20(_data)), _id / 2);

            // Preset borrower token's URI
            _setURI(_id + 1, _collateralURI);
        }
        /* Borrower Token */
        else {
            _checkRole(_tokenAdminRole, _to);
        }

        // Mint ALC debt tokens
        _mint(_to, _id, _amount, _data);
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
        if (_from == address(0)) {
            require(_ids.length == 1, "Invalid Anza mint");
            require(
                ((_ids[0] % 2) == 0) || (totalSupply(_ids[0]) == 0),
                "Cannot remint replica"
            );

            for (uint256 i = 0; i < _ids.length; ++i) {
                _incrementTotalSupply(_ids[i], _amounts[i]);
            }
        } else {
            for (uint256 i = 0; i < _ids.length; ++i) {
                uint256 _id = _ids[i];

                // // Conditionally update borrower token admin on transfer.
                // if (_id % 2 == 1) __updateBorrowerRole(_from, _to, _id / 2);
            }
        }

        if (_to == address(0)) {
            for (uint256 i = 0; i < _ids.length; ++i) {
                uint256 _id = _ids[i];
                uint256 amount = _amounts[i];
                uint256 supply = totalSupply(_id);
                require(
                    supply >= amount,
                    "AnzaToken: burn amount exceeds totalSupply"
                );
                unchecked {
                    _setTotalSupply(_id, supply - amount);
                }
            }
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _afterTokenTransfer(
        address,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory,
        bytes memory _data
    ) internal override {
        // Set token owners
        if (_to != address(0)) _setOwner(_ids[0], _to);

        // Set the replica token's owner automatically
        if (_from == address(0))
            _setOwner(_ids[0] + 1, address(bytes20(_data)));
    }

    function __debtTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        uint256 /* _amount */,
        bytes memory /* _data */
    ) private {
        __updateBorrowerRole(_from, _to, _debtId);

        uint256 _id = borrowerTokenId(_debtId);
        if (exists(_id)) super._safeTransferFrom(_from, _to, _id, 1, "");
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
            __updateBorrowerRole(_from, _to, _debtIds[i]);

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

    function __updateBorrowerRole(
        address _oldBorrower,
        address _newBorrower,
        uint256 _debtId
    ) private {
        bytes32 _newTokenAdminRole = keccak256(
            abi.encodePacked(_newBorrower, _debtId)
        );

        // Close out prev role
        _revokeRole(
            keccak256(abi.encodePacked(_oldBorrower, _debtId)),
            _oldBorrower
        );

        // Only allow treasurer to grant/revoke access control.
        // This is necessary to allow a single account to recall
        // the collateral upon full repayment.
        _setRoleAdmin(_newTokenAdminRole, _TREASURER_);

        // Grant the borrower's address token admin access control.
        _grantRole(_newTokenAdminRole, _newBorrower);
    }
}
