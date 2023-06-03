// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/console.sol";

import "../domain/LoanContractFIRIntervals.sol";
import "../domain/LoanContractTermMaps.sol";
import "../domain/LoanNotaryTypeHashes.sol";

import {ILoanNotaryErrors, ILoanNotary, IDebtNotary} from "../interfaces/ILoanNotary.sol";
import "../abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library LibLoanNotary {
    bytes32 internal constant _typeHash =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    struct DomainSeperator {
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

    function recoverSigner(
        ILoanNotary.ContractParams memory _contractParams,
        DomainSeperator memory _domainSeperator,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 _message = typeDataHash(_contractParams, _domainSeperator);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    function domainSeperator(
        DomainSeperator memory _domainSeperator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _typeHash,
                    keccak256(abi.encodePacked(_domainSeperator.name)),
                    keccak256(abi.encodePacked(_domainSeperator.version)),
                    _domainSeperator.chainId,
                    _domainSeperator.contractAddress
                )
            );
    }

    function typeDataHash(
        ILoanNotary.ContractParams memory _contractParams,
        DomainSeperator memory _domainSeperator
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeperator(_domainSeperator),
                    structHash(_contractParams)
                )
            );
    }

    function typeDataHash(
        IDebtNotary.DebtListingParams memory _debtListingParams,
        DomainSeperator memory _domainSeperator
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeperator(_domainSeperator),
                    structHash(_debtListingParams)
                )
            );
    }

    function structHash(
        ILoanNotary.ContractParams memory _contractParams
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash(
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

    function structHash(
        IDebtNotary.DebtListingParams memory _debtListingParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash(
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

    function typeHash(
        address _borrower,
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (bytes32) {
        return
            IERC721(_collateralAddress).ownerOf(_collateralId) == _borrower
                ? initLoanContract__typeHash0
                : initLoanContract__typeHash1;
    }

    function typeHash(
        address /*_borrower*/,
        uint256 /*_debtId*/
    ) public pure returns (bytes32) {
        return buyDebt__typeHash0;
    }

    function hashMessage(
        uint256 _principal,
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _principal,
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
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
