// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";

import "../domain/LoanContractRoles.sol";

import "./AnzaERC1155URIStorage.sol";
import "../interfaces/IAnzaToken.sol";
import "../interfaces/ICollateralVault.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AnzaToken is AnzaERC1155URIStorage, AccessControl {
    /* ------------------------------------------------ *
     *                Contract Constants                *
     * ------------------------------------------------ */
    string private constant _TOKEN_NAME_ = "Anza Debt Token";
    string private constant _TOKEN_SYMBOL_ = "ADT";

    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    // Mapping from token ID to owner address
    mapping(uint256 => address) private __owners;
    mapping(uint256 => uint256) private _totalSupply;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_LOAN_CONTRACT_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);
        _setRoleAdmin(_DEBT_STOREFRONT_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return
            _interfaceId == type(IAnzaToken).interfaceId ||
            ERC1155.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }

    function name() public pure returns (string memory) {
        return _TOKEN_NAME_;
    }

    function symbol() public pure returns (string memory) {
        return _TOKEN_SYMBOL_;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return __owners[_tokenId];
    }

    function borrowerOf(uint256 _debtId) public view returns (address) {
        return __owners[(_debtId * 2) + 1];
    }

    function lenderOf(uint256 _debtId) public view returns (address) {
        return __owners[_debtId * 2];
    }

    function checkBorrowerOf(
        address _account,
        uint256 _debtId
    ) external view returns (bool) {
        return
            hasRole(keccak256(abi.encodePacked(_account, _debtId)), _account);
    }

    function borrowerTokenId(uint256 _debtId) public pure returns (uint256) {
        return (_debtId * 2) + 1;
    }

    function lenderTokenId(uint256 _debtId) public pure returns (uint256) {
        return _debtId * 2;
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view returns (bool) {
        return totalSupply(id) > 0;
    }

    function anzaTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        bytes memory _data
    ) external onlyRole(_TREASURER_) {
        uint256 _id = borrowerTokenId(_debtId);

        if (exists(_id)) {
            safeTransferFrom(_from, _to, _id, 1, _data);
        } else {
            __updateBorrowerRole(_from, _to, _debtId);
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

    function burn(address _account, uint256 _id, uint256 _value) external {
        if (!exists(_id)) return;

        require(
            _account == msg.sender || isApprovedForAll(_account, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(_account, _id, _value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function burnBorrowerToken(uint256 _debtId) external onlyRole(_TREASURER_) {
        uint256 _borrowerToken = borrowerTokenId(_debtId);

        if (!exists(_borrowerToken)) return;

        _burn(borrowerOf(_debtId), _borrowerToken, 1);
    }

    function isApprovedForAll(
        address _account,
        address _operator
    ) public view override returns (bool) {
        // This token is recallable by the Anza treasurer
        // account
        return
            hasRole(_TREASURER_, _operator) ||
            super.isApprovedForAll(_account, _operator);
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
                ((_ids[0] % 2) == 0) || (_totalSupply[_ids[0]] == 0),
                "Cannot remint replica"
            );

            for (uint256 i = 0; i < _ids.length; ++i) {
                _totalSupply[_ids[i]] += _amounts[i];
            }
        } else {
            for (uint256 i = 0; i < _ids.length; ++i) {
                uint256 _id = _ids[i];

                // Conditionally update borrower token admin on transfer.
                if (_id % 2 == 1) __updateBorrowerRole(_from, _to, _id / 2);
            }
        }

        if (_to == address(0)) {
            for (uint256 i = 0; i < _ids.length; ++i) {
                uint256 _id = _ids[i];
                uint256 amount = _amounts[i];
                uint256 supply = _totalSupply[_id];
                require(
                    supply >= amount,
                    "AnzaToken: burn amount exceeds totalSupply"
                );
                unchecked {
                    _totalSupply[_id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _afterTokenTransfer(
        address,
        address,
        address _to,
        uint256[] memory _ids,
        uint256[] memory,
        bytes memory
    ) internal override {
        // Set token owners
        if (_to != address(0)) __owners[_ids[0]] = _to;
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
