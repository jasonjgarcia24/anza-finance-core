// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/forge-std/src/console.sol";

import "../domain/LoanContractFIRIntervals.sol";
import "../domain/LoanContractTermMaps.sol";
import "../domain/LoanNotaryTypeHashes.sol";

import {ILoanNotaryErrors, ILoanNotary, IListingNotary, IRefinanceNotary} from "../interfaces/ILoanNotary.sol";
import "../abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library LibLoanNotary {
    bytes32 internal constant _typeHash =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    struct DomainSeparator {
        string name;
        string version;
        uint256 chainId;
        address contractAddress;
    }

    function createContractTerms(
        uint8 _firInterval,
        uint8 _fixedInterestRate,
        uint8 _isFixed,
        uint8 _commital,
        uint32 _gracePeriod,
        uint32 _duration,
        uint32 _termsExpiry,
        uint8 _lenderRoyalties
    ) public pure returns (bytes32 _contractTerms) {
        assembly {
            mstore(0x20, _firInterval)
            mstore(0x1f, _fixedInterestRate)

            switch eq(_isFixed, 0x01)
            case true {
                mstore(0x1e, add(0x65, _commital))
            }
            case false {
                mstore(0x1e, _commital)
            }

            mstore(0x0d, _gracePeriod)
            mstore(0x09, _duration)
            mstore(0x05, _termsExpiry)
            mstore(0x01, _lenderRoyalties)

            _contractTerms := mload(0x20)
        }
    }

    /**
     * {see LoanNotary:LoanNotary-__recoverSigner}
     */
    function recoverSigner(
        ILoanNotary.ContractParams memory _contractParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(_contractParams, _domainSeparator);

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * {see LoanNotary:ListingNotary-__recoverSigner}
     */
    function recoverSigner(
        IListingNotary.ListingParams memory _listingParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(_listingParams, _domainSeparator);

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * {see LoanNotary:RefinanceNotary-__recoverSigner}
     */
    function recoverSigner(
        IRefinanceNotary.RefinanceParams memory _refinanceParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(_refinanceParams, _domainSeparator);

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * {see LoanNotary:LoanNotary-__domainSeparator}
     */
    function domainSeparator(
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _typeHash,
                    keccak256(abi.encodePacked(_domainSeparator.name)),
                    keccak256(abi.encodePacked(_domainSeparator.version)),
                    _domainSeparator.chainId,
                    _domainSeparator.contractAddress
                )
            );
    }

    /**
     * {see LoanNotary:LoanNotary-__typeDataHash}
     */
    function typeDataHash(
        ILoanNotary.ContractParams memory _contractParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_contractParams)
                )
            );
    }

    /**
     * {see LoanNotary:ListingNotary-__typeDataHash}
     */
    function typeDataHash(
        IListingNotary.ListingParams memory _listingParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_listingParams)
                )
            );
    }

    /**
     * {see LoanNotary:RefinanceNotary-__typeDataHash}
     */
    function typeDataHash(
        IRefinanceNotary.RefinanceParams memory _refinanceParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_refinanceParams)
                )
            );
    }

    function structHash(
        ILoanNotary.ContractParams memory _contractParams
    ) public pure returns (bytes32) {
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

    function structHash(
        IListingNotary.ListingParams memory _listingParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _LISTING_PARAMS_ENCODE_TYPE_HASH_,
                    _listingParams.price,
                    _listingParams.debtId,
                    _listingParams.listingNonce,
                    _listingParams.termsExpiry
                )
            );
    }

    function structHash(
        IRefinanceNotary.RefinanceParams memory _refinanceParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _REFINANCE_PARAMS_ENCODE_TYPE_HASH_,
                    _refinanceParams.price,
                    _refinanceParams.debtId,
                    _refinanceParams.contractTerms,
                    _refinanceParams.listingNonce,
                    _refinanceParams.termsExpiry
                )
            );
    }

    function splitSignature(
        bytes memory _signature
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (_signature.length != 65)
            revert ILoanNotaryErrors.InvalidSignatureLength();

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }
}
