// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";
import "./interfaces/ILoanNotary.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of
 * typed structured data.
 *
 * This contract implements the EIP 712 type-specific encoding of signed loan contract terms.
 *
 * This contract implements the EIP 712 V4 domain separator part of the encoding scheme:
 *   keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)))
 *
 * The final step of the encoding is the message digest that is then signed via ECDSA ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 */

contract LoanNotary is ILoanNotary {
    bytes32 private constant __initLoanContract__typeHash0 =
        keccak256(
            "InitLoanContract(bytes32 _contractTerms,address _collateralAddress,uint256 _collateralId,bytes _borrowerSignature)"
        );
    bytes32 private constant __initLoanContract__typeHash1 =
        keccak256(
            "InitLoanContract(bytes32 _contractTerms,uint256 _debtId,bytes _borrowerSignature)"
        );

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
        SignatureParams memory _signatureParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        _signatureParams.borrower = ownerOf(_assetId);

        if (
            _signatureParams.borrower !=
            __recoverSigner(_signatureParams, _borrowerSignature) ||
            _signatureParams.borrower == msg.sender
        ) revert InvalidParticipant();

        return _signatureParams.borrower;
    }

    function __recoverSigner(
        SignatureParams memory _signatureParams,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 _message = __typeDataHash(_signatureParams);

        (uint8 v, bytes32 r, bytes32 s) = __splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    function __typeDataHash(
        SignatureParams memory _signatureParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    __domainSeperator,
                    __structHash(_signatureParams)
                )
            );
    }

    function __structHash(
        SignatureParams memory _signatureParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    __typeHash(
                        _signatureParams.borrower,
                        _signatureParams.collateralAddress,
                        _signatureParams.collateralId
                    ),
                    _signatureParams.borrower,
                    _signatureParams.collateralNonce
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
                ? __initLoanContract__typeHash0
                : __initLoanContract__typeHash1;
    }

    function __splitSignature(
        bytes memory _signature
    ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}
