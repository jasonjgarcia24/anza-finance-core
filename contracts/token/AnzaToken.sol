// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AnzaERC1155URIStorage.sol";

contract AnzaToken is AnzaERC1155URIStorage {
    /* ------------------------------------------------ *
     *                Contract Constants                *
     * ------------------------------------------------ */
    string private constant _TOKEN_NAME_ = "Anza Debt Token";
    string private constant _TOKEN_SYMBOL_ = "ADT";

    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address private immutable __debtFactory;

    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    // Mapping from token ID to owner address
    mapping(uint256 => address) private __owners;

    constructor(address _debtFactory) AnzaERC1155("") {
        __debtFactory = _debtFactory;
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

    function mint(
        address[2] memory _to,
        uint256[2] memory _ids,
        uint256[2] memory _amounts,
        string calldata _collateralURI,
        bytes memory _data
    ) external {
        // Mint debt ALC debt tokens for borrower and lender
        _mintAnzaBatch(_to, _ids, _amounts, _data);

        // Set borrower token's URI
        _setURI(_ids[0], _collateralURI);
    }

    function burn(address account, uint256 id, uint256 value) external {
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
        if (_operator == __debtFactory) {
            return true;
        }

        return super.isApprovedForAll(_account, _operator);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _afterAnzaTokenTransfer(
        address,
        address from,
        address[2] memory to,
        uint256[2] memory ids,
        uint256[2] memory,
        bytes memory
    ) internal override {
        if (from != address(0)) {
            return;
        }

        // Set token owners
        __owners[ids[0]] = to[0];
        __owners[ids[1]] = to[1];
    }
}
