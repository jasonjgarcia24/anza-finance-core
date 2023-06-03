// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";
import {ILoanNotary, IDebtNotary} from "./interfaces/ILoanNotary.sol";
import {LibLoanNotary} from "./libraries/LibLoanNotary.sol";
import "./domain/LoanNotaryTypeHashes.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of
 * typed structured data.
 *
 */

/**
 * This contract implements the EIP 712 type-specific encoding of signed loan contract terms.
 *
 * This contract implements the EIP 712 V4 domain separator part of the encoding scheme:
 *   keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)))
 *
 * The final step of the encoding is the message digest that is then signed via ECDSA.
 *
 * The implementation of the domain separator was designed to be as efficient as possible while
 * still properly updating the chain id to protect against replay attacks on an eventual fork of
 * the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the
 * JSON RPC method https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in
 * MetaMask].
 */
abstract contract LoanNotary is ILoanNotary {
    bytes32 private immutable __domainSeperator;

    constructor(string memory _contractName, string memory _contractVersion) {
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __domainSeperator = keccak256(
            abi.encode(
                typeHash,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    function _getBorrower(
        uint256 _assetId,
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        _contractParams.borrower = ownerOf(_assetId);

        if (
            _contractParams.borrower !=
            __recoverSigner(_contractParams, _borrowerSignature) ||
            _contractParams.borrower == msg.sender
        ) revert InvalidParticipant();

        return _contractParams.borrower;
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `_signature`. This address can then be used for verification purposes.
     *
     * {see ECDSA-recover}
     */
    function __recoverSigner(
        ContractParams memory _contractParams,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 _message = __typeDataHash(_contractParams);

        (uint8 v, bytes32 r, bytes32 s) = LibLoanNotary.splitSignature(
            _signature
        );

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     */
    function __typeDataHash(
        ContractParams memory _contractParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    __domainSeperator,
                    __structHash(_contractParams)
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     */
    function __structHash(
        ContractParams memory _contractParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    __typeHash(
                        _contractParams.borrower,
                        _contractParams.collateralAddress,
                        _contractParams.collateralId
                    ),
                    _contractParams.principal,
                    _contractParams.contractTerms,
                    _contractParams.collateralAddress,
                    _contractParams.collateralId,
                    _contractParams.collateralNonce
                )
            );
    }

    function __typeHash(
        address _borrower,
        address _collateralAddress,
        uint256 _collateralId
    ) private view returns (bytes32) {
        return
            IERC721(_collateralAddress).ownerOf(_collateralId) == _borrower
                ? initLoanContract__typeHash0
                : initLoanContract__typeHash1;
    }

    // function __splitSignature(
    //     bytes memory _signature
    // ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
    //     if (_signature.length != 65) revert InvalidSignatureLength();

    //     assembly {
    //         r := mload(add(_signature, 0x20))
    //         s := mload(add(_signature, 0x40))
    //         v := byte(0, mload(add(_signature, 0x60)))
    //     }
    // }
}

/**
 * This contract implements the EIP 712 type-specific encoding of signed loan contract terms.
 *
 * This contract implements the EIP 712 V4 domain separator part of the encoding scheme:
 *   keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)))
 *
 * The final step of the encoding is the message digest that is then signed via ECDSA.
 *
 * The implementation of the domain separator was designed to be as efficient as possible while
 * still properly updating the chain id to protect against replay attacks on an eventual fork of
 * the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the
 * JSON RPC method https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in
 * MetaMask].
 */
abstract contract DebtNotary is IDebtNotary {
    bytes32 private immutable __domainSeperator;

    constructor(string memory _contractName, string memory _contractVersion) {
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __domainSeperator = keccak256(
            abi.encode(
                typeHash,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    function _getBorrower(
        uint256 _assetId,
        DebtListingParams memory _debtListingParams,
        bytes memory _sellerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        _debtListingParams.borrower = ownerOf(_assetId);

        if (
            _debtListingParams.borrower !=
            __recoverSigner(_debtListingParams, _sellerSignature) ||
            _debtListingParams.borrower == msg.sender
        ) revert InvalidParticipant();

        return _debtListingParams.borrower;
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `_signature`. This address can then be used for verification purposes.
     *
     * {see ECDSA-recover}
     */
    function __recoverSigner(
        DebtListingParams memory _debtListingParams,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 _message = __typeDataHash(_debtListingParams);

        (uint8 v, bytes32 r, bytes32 s) = LibLoanNotary.splitSignature(
            _signature
        );

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     */
    function __typeDataHash(
        DebtListingParams memory _debtListingParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    __domainSeperator,
                    __structHash(_debtListingParams)
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     */
    function __structHash(
        DebtListingParams memory _debtListingParams
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    __typeHash(
                        _debtListingParams.borrower,
                        _debtListingParams.debtId
                    ),
                    _debtListingParams.listingTerms,
                    _debtListingParams.price,
                    _debtListingParams.debtId,
                    _debtListingParams.termsExpiry
                )
            );
    }

    function __typeHash(
        address /*_borrower*/,
        uint256 /*_debtId*/
    ) private pure returns (bytes32) {
        return buyDebt__typeHash0;
    }

    // function __splitSignature(
    //     bytes memory _signature
    // ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
    //     if (_signature.length != 65) revert InvalidSignatureLength();

    //     assembly {
    //         r := mload(add(_signature, 0x20))
    //         s := mload(add(_signature, 0x40))
    //         v := byte(0, mload(add(_signature, 0x60)))
    //     }
    // }
}
