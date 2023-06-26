// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanNotaryTypeHashes.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {ILoanNotary, IDebtNotary, ISponsorshipNotary, IRefinanceNotary} from "@services-interfaces/ILoanNotary.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title AnzaNotary
 * @author jjgarcia.eth
 * @notice The AnzaNotary library provides functions to recovery and validate
 * debt transaction signatures.
 *
 * @dev This library is an interface for using the EIP-1271 standard for
 * signature validation. Currently, this library supports debt transaction
 * signature validation for initial Loan terms and Debt, Refinance, and
 * Sponsorship sales.
 *
 * See {LoanNotary:LoanNotary, LoanNotary:DebtNotary,
 * LoanNotary:RefinanceNotary, LoanNotary:SponsorshipNotary}.
 */
library AnzaNotary {
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
     * {see LoanNotary:DebtNotary-__recoverSigner}
     */
    function recoverSigner(
        IDebtNotary.DebtParams memory _debtParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(_debtParams, _domainSeparator);

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
     * {see LoanNotary:SponsorshipNotary-__recoverSigner}
     */
    function recoverSigner(
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(_sponsorshipParams, _domainSeparator);

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
                    _TYPE_HASH_,
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
     * {see LoanNotary:DebtNotary-__typeDataHash}
     */
    function typeDataHash(
        IDebtNotary.DebtParams memory _debtParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_debtParams)
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

    /**
     * {see LoanNotary:SponsorshipNotary-__typeDataHash}
     */
    function typeDataHash(
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_sponsorshipParams)
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
        IDebtNotary.DebtParams memory _debtParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DEBT_PARAMS_ENCODE_TYPE_HASH_,
                    _debtParams.price,
                    _debtParams.collateralAddress,
                    _debtParams.collateralId,
                    _debtParams.listingNonce,
                    _debtParams.termsExpiry
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

    function structHash(
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _SPONSORSHIP_PARAMS_ENCODE_TYPE_HASH_,
                    _sponsorshipParams.price,
                    _sponsorshipParams.debtId,
                    _sponsorshipParams.listingNonce,
                    _sponsorshipParams.termsExpiry
                )
            );
    }

    function splitSignature(
        bytes memory _signature
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (_signature.length != 65)
            revert StdNotaryErrors.InvalidSignatureLength();

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }
}
