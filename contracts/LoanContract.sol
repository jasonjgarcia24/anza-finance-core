// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {LibOfficerRoles as Roles, LibLoanContractMetadata as Metadata, LibLoanContractInit as Init, LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";
import {LibLoanContractStates as States} from "./utils/LibLoanContractStates.sol";
import "./interfaces/ILoanContract.sol";
import "hardhat/console.sol";

contract LoanContract is
    ILoanContract,
    AccessControl,
    ERC1155URIStorage,
    ERC1155Holder,
    ReentrancyGuard
{
    bytes32 public constant _BORROWER_TOKEN_ = keccak256("BORROWER_TOKEN");
    bytes32 public constant _LENDER_TOKEN_ = keccak256("LENDER_TOKEN");

    string private constant _name = "Anza Loan Contract";
    string private constant _symbol = "ALC";
    address public immutable arbiter;

    mapping(address => mapping(uint256 => uint256[])) public debtIds;

    // - [0..63] `termsExpiry`
    // - [64..127] `principal`
    // - [128..191] `duration`
    // - [192..223] `gracePeriod`
    // - [224..225] `loanState`
    // - [226..227] `aux`
    mapping(uint256 => bytes32) private _packedDebtTerms;
    mapping(uint256 => address) private __owners;
    mapping(uint256 => uint256) private _totalSupply;

    uint256 public totalDebts;

    States.LoanState[] public loanStates;
    Metadata.TokenData[] public tokens;

    constructor(
        address _admin,
        address _arbiter,
        address _treasurer,
        address _collector,
        string memory _nftsURI,
        string memory _baseURI
    ) ERC1155(_baseURI) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);
        _setRoleAdmin(Roles._COLLECTOR_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, _admin);
        _grantRole(Roles._TREASURER_, _treasurer);
        _grantRole(Roles._COLLECTOR_, _collector);

        arbiter = _arbiter;
        _setBaseURI(_nftsURI);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(AccessControl, ERC1155Receiver, ERC1155)
        returns (bool)
    {
        return
            _interfaceId == type(ILoanContract).interfaceId ||
            ERC1155.supportsInterface(_interfaceId) ||
            ERC1155Receiver.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /*
     * This should report back only the total debt tokens, not the ALC NFTs.
     * TODO: Test
     */
    function totalDebtSupply(uint256 _debtId) public view returns (uint256) {
        return _totalSupply[_debtId];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function debtExists(uint256 _debtId) public view returns (bool) {
        return totalDebtSupply(_debtId) > 0;
    }

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debtIds[_collateralAddress][_collateralId].length;
    }

    // TODO: Test
    function initLoanContract(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes calldata _borrowerSignature
    ) external payable {
        // Validate borrower participation
        IERC721 _collateralToken = IERC721(_collateralAddress);
        address _borrower = _collateralToken.ownerOf(_collateralId);

        if (
            _borrower !=
            __recoverSigner(
                _contractTerms,
                _collateralAddress,
                _collateralId,
                _collateralNonce,
                _borrowerSignature
            )
        ) revert InvalidParticipant({account: _borrower});

        // Add debt ID to collateral mapping
        debtIds[_collateralAddress][_collateralId].push(totalDebts);
        _packedDebtTerms[totalDebts] = _contractTerms;

        uint256 _principal = principal(totalDebts);
        if (msg.value != _principal) _revert(InsufficientFunds.selector);

        // Transfer collateral to arbiter
        _collateralToken.safeTransferFrom(
            _borrower,
            arbiter,
            _collateralId,
            ""
        );

        // Transfer funds to borrower
        (bool _success, ) = _borrower.call{value: _principal}("");
        require(_success);

        // Mint debt ALC debt tokens for borrower and lender
        _mint(msg.sender, totalDebts, _principal, "");
        _mint(_borrower, totalDebts + 1, _principal, "");

        // Emit initialization event
        emit LoanContractInitialized(
            _collateralAddress,
            _collateralId,
            totalDebts
        );

        // Setup for next debt ID
        totalDebts += 1;
    }

    function termsExpiry(uint256 _debtId)
        public
        view
        returns (uint256 _termsExpiry)
    {
        bytes32 _contractTerms = _packedDebtTerms[_debtId];
        uint64 __termsExpiry;

        assembly {
            __termsExpiry := _contractTerms
        }

        unchecked {
            _termsExpiry = __termsExpiry;
        }
    }

    function principal(uint256 _debtId)
        public
        view
        returns (uint256 _principal)
    {
        bytes32 _contractTerms = _packedDebtTerms[_debtId];
        uint64 __principal;

        assembly {
            mstore(0x08, _contractTerms)
            __principal := mload(0)
        }

        unchecked {
            _principal = __principal;
        }
    }

    function duration(uint256 _debtId) public view returns (uint256 _duration) {
        bytes32 _contractTerms = _packedDebtTerms[_debtId];
        uint64 __duration;

        assembly {
            mstore(0x10, _contractTerms)
            __duration := mload(0)
        }

        unchecked {
            _duration = __duration;
        }
    }

    function gracePeriod(uint256 _debtId)
        public
        view
        returns (uint256 _gracePeriod)
    {
        bytes32 _contractTerms = _packedDebtTerms[_debtId];
        uint32 __gracePeriod;

        assembly {
            mstore(0x18, _contractTerms)
            __gracePeriod := mload(0)
        }

        unchecked {
            _gracePeriod = __gracePeriod;
        }
    }

    function fixedInterestRate(uint256 _debtId)
        public
        view
        returns (uint256 _fixedInterestRate)
    {
        bytes32 _contractTerms = _packedDebtTerms[_debtId];
        uint8 __fixedInterestRate;

        assembly {
            mstore(0x1c, _contractTerms)
            __fixedInterestRate := mload(0)
        }

        unchecked {
            _fixedInterestRate = __fixedInterestRate;
        }
    }

    function loanState(uint256 _debtId)
        public
        view
        returns (uint256 _loanState)
    {
        bytes32 _contractTerms = _packedDebtTerms[_debtId];
        uint8 __loanState;

        assembly {
            mstore(0x1d, _contractTerms)
            __loanState := mload(0)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address _owner = __owners[_tokenId];

        return _owner;
    }

    function borrowerOf(uint256 _debtId) external view returns (address) {
        return ownerOf((2 * _debtId) + 1);
    }

    function lenderOf(uint256 _debtId) public view returns (address) {
        return ownerOf(2 * _debtId);
    }

    function recordPayment(uint256 _debtId, uint256 _payment)
        external
        onlyRole(Roles._TREASURER_)
    {
        console.logAddress(msg.sender);
        Metadata.TokenData storage _token = tokens[_debtId];

        if (_token.unpaidBalance <= 0)
            revert InactiveLoanState({debtId: _debtId});

        if (_token.unpaidBalance < _payment)
            revert InvalidFundsTransfer({amount: _payment});

        // Burn ALC debt token
        _burn(msg.sender, (_debtId * 2) + 1, _payment);

        // Update loan contract state
        _token.withdrawableBalance += _payment;
        _token.unpaidBalance -= _payment;
    }

    function withdrawPayment(uint256 _debtId, uint256 _amount)
        external
        nonReentrant
    {
        if (msg.sender != lenderOf(_debtId))
            revert InvalidParticipant({account: msg.sender});

        Metadata.TokenData storage _token = tokens[_debtId];

        if (_token.withdrawableBalance < _amount)
            revert InvalidFundsTransfer({amount: _amount});

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success);

        // Burn ALC lender token
        _burn(msg.sender, _debtId * 2, _amount);

        // Update loan contract state
        _token.withdrawableBalance -= _amount;
    }

    // function burn(
    //     address account,
    //     uint256 id,
    //     uint256 value
    // ) public virtual {
    //     require(
    //         account == msg.sender || isApprovedForAll(account, msg.sender),
    //         "ERC1155: caller is not token owner nor approved"
    //     );

    //     _burn(account, id, value);
    // }

    // function burnBatch(
    //     address account,
    //     uint256[] memory ids,
    //     uint256[] memory values
    // ) public virtual {
    //     require(
    //         account == msg.sender || isApprovedForAll(account, msg.sender),
    //         "ERC1155: caller is not token owner nor approved"
    //     );

    //     _burnBatch(account, ids, values);
    // }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal override {
        __owners[ids[0]] = to;

        // Update total ALC token supply
        if (from == address(0)) {
            _totalSupply[ids[0]] += amounts[0];
        }

        if (to == address(0)) {
            uint256 id = ids[0];
            uint256 amount = amounts[0];
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

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _afterTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal override {
        if (from != address(0)) {
            return;
        }

        // Set token URI
        if (ids[0] % 2 == 1) {
            _setURI(ids[0], Strings.toString(ids[0]));
        } else if (ids[0] % 2 == 0) {
            _setURI(
                ids[0],
                string(
                    abi.encodePacked("debt-token/", Strings.toString(ids[0]))
                )
            );
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }

    function __recoverSigner(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes memory _signature
    ) private pure returns (address) {
        bytes32 _message = __prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = __splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }

    function __prefixed(bytes32 _hash) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function __splitSignature(bytes memory _signature)
        private
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}
