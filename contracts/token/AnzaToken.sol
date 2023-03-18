// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "./AnzaERC1155URIStorage.sol";
import "./interfaces/IAnzaToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {LibOfficerRoles as Roles} from "../libraries/LibLoanContract.sol";

contract AnzaToken is AnzaERC1155URIStorage, AccessControl, IAnzaToken {
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

    constructor(address _admin, address _debtFactory, address _treasurer) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._LOAN_CONTRACT_, Roles._ADMIN_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, _admin);
        _grantRole(Roles._LOAN_CONTRACT_, _debtFactory);
        _grantRole(Roles._TREASURER_, _treasurer);
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

    function borrowerTokenId(uint256 _debtId) public pure returns (uint256) {
        return _debtId * 2;
    }

    function lenderTokenId(uint256 _debtId) public pure returns (uint256) {
        return (_debtId * 2) + 1;
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
    function exists(uint256 id) public view virtual returns (bool) {
        return AnzaToken.totalSupply(id) > 0;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string calldata _collateralURI,
        bytes memory _data
    ) external onlyRole(Roles._LOAN_CONTRACT_) {
        address _borrower = address(bytes20(_data));
        bytes32 _tokenAdminRole = keccak256(_data);

        /* Lender Token */
        if (_id % 2 == 0) {
            _checkRole(Roles._LOAN_CONTRACT_, msg.sender);

            // Only allow treasurer to grant/revoke access control.
            // This is necessary to allow a single account to recall
            // the collateral upon full repayment.
            _setRoleAdmin(_tokenAdminRole, Roles._TREASURER_);
            _grantRole(_tokenAdminRole, _borrower);

            // Preset borrower token's URI
            _setURI(_id + 1, _collateralURI);
        }
        /* Borrower Token */
        else {
            _checkRole(_tokenAdminRole, _borrower);
        }

        // Mint ALC debt tokens
        _mint(_to, _id, _amount, _data);
    }

    function burn(address account, uint256 id, uint256 value) external {
        if (exists(id) == false) return;

        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
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

    function isApprovedForAll(
        address _account,
        address _operator
    ) public view override returns (bool) {
        return
            hasRole(Roles._TREASURER_, _operator) ||
            super.isApprovedForAll(_account, _operator);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            require(ids.length == 1, "Invalid Anza mint");

            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(
                    supply >= amount,
                    "ERC1155: burn amount exceeds totalSupply"
                );
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _afterTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal override {
        if (from != address(0)) {
            return;
        }

        // Set token owners
        __owners[ids[0]] = to;
    }
}
