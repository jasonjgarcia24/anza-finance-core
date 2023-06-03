// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/console.sol";

import "./domain/LoanNotaryTypeHashes.sol";

import {ILoanNotary, IDebtNotary} from "./interfaces/ILoanNotary.sol";
import {LibLoanNotary} from "./libraries/LibLoanNotary.sol";
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
    /**
     * @dev Returns the value that is unique to each contract that uses EIP-712.
     * This hashed value is used to prevent replay attacks from malicious actors
     * attempting to use a signed message to execute the same action multiple
     * times.
     */
    bytes32 private immutable __domainSeparator;

    constructor(string memory _contractName, string memory _contractVersion) {
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __domainSeparator = keccak256(
            abi.encode(
                typeHash,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Returns the verified borrower of a signed set of loan contract
     * terms.
     *
     * @param _assetId the collateral or debt ID of the asset. If this is
     * called as an original loan contract for a new loan, this should be the
     * collateral ID. If this is called as a loan contract refinance for
     * existing debt, this should be the debt ID.
     * @param _contractParams the loan contract terms.
     * @param _borrowerSignature the signed loan contract terms.
     * @param ownerOf the function used to identify the recorded borrower. If
     * this is called as an original loan contract for a new loan, this should
     * be a IERC721.ownerOf call on the collateral contract. If this is called
     * as a loan contract refinance for existing debt, this should be a
     * IAnzaToken.borrowerOf call on the debt contract.
     */
    function _getBorrower(
        uint256 _assetId,
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        address _borrower = ownerOf(_assetId);

        if (
            _borrower == msg.sender ||
            _borrower != __recoverSigner(_contractParams, _borrowerSignature)
        ) revert InvalidParticipant();

        return _borrower;
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
                    __domainSeparator,
                    __structHash(_contractParams)
                )
            );
    }

    /**
     * @dev Returns the hash of a structured message. This hash shall be
     * combined with the `domainSeparator` and signed by the signer using their
     * private key to produce a signature. The signature is then used to verify
     * that the structured message originated
     * from the signer.
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
     */
    function __structHash(
        ContractParams memory _contractParams
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _CONTRACT_PARAMS_ENCODE_TYPE_HASH_,
                    _contractParams.principal,
                    _contractParams.contractTerms,
                    _contractParams.collateralAddress,
                    _contractParams.collateralId,
                    _contractParams.collateralNonce
                )
            );
    }
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
    /**
     * @dev Returns the value that is unique to each contract that uses EIP-712.
     * This hashed value is used to prevent replay attacks from malicious actors
     * attempting to use a signed message to execute the same action multiple
     * times.
     */
    bytes32 private immutable __domainSeparator;

    constructor(string memory _contractName, string memory _contractVersion) {
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __domainSeparator = keccak256(
            abi.encode(
                typeHash,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Returns the verified borrower of a signed set of loan contract
     * terms.
     *
     * @param _assetId the debt ID of the asset.
     * @param _debtListingParams the debt listing terms.
     * @param _sellerSignature the signed debt listing terms.
     * @param ownerOf the function used to identify the recorded borrower.
     */
    function _getBorrower(
        uint256 _assetId,
        DebtListingParams memory _debtListingParams,
        bytes memory _sellerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        address _borrower = ownerOf(_assetId);

        if (
            _borrower == msg.sender ||
            _borrower != __recoverSigner(_debtListingParams, _sellerSignature)
        ) revert InvalidParticipant();

        return _borrower;
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
                    __domainSeparator,
                    __structHash(_debtListingParams)
                )
            );
    }

    /**
     * @dev Returns the hash of a structured message. This hash shall be
     * combined with the `domainSeparator` and signed by the signer using their
     * private key to produce a signature. The signature is then used to verify
     * that the structured message originated
     * from the signer.
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
     */
    function __structHash(
        DebtListingParams memory _debtListingParams
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DEBT_LISTING_PARAMS_ENCODE_TYPE_HASH_,
                    _debtListingParams.listingTerms,
                    _debtListingParams.price,
                    _debtListingParams.debtId,
                    _debtListingParams.termsExpiry
                )
            );
    }
}
