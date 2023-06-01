// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../domain/LoanContractFIRIntervals.sol";
import "../domain/LoanContractTermMaps.sol";

import "../interfaces/ILoanNotary.sol";
import "../abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library LibLoanNotary {
    bytes32 internal constant _initLoanContract__typeHash0 =
        keccak256(
            "InitLoanContract(bytes32 _contractTerms,address _collateralAddress,uint256 _collateralId,bytes _borrowerSignature)"
        );
    bytes32 internal constant _initLoanContract__typeHash1 =
        keccak256(
            "InitLoanContract(bytes32 _contractTerms,uint256 _debtId,bytes _borrowerSignature)"
        );

    bytes32 internal constant _typeHash =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    struct ContractTerms {
        uint256 firInterval;
        uint8 fixedInterestRate;
        uint8 isFixed;
        uint8 commital;
        uint128 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
        uint8 lenderRoyalties;
    }

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
        ILoanNotary.SignatureParams memory _signatureParams,
        DomainSeperator memory _domainSeperator,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 _message = typeDataHash(_signatureParams, _domainSeperator);

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ecrecover(_message, v, r, s);
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
        ILoanNotary.SignatureParams memory _signatureParams,
        DomainSeperator memory _domainSeperator
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeperator(_domainSeperator),
                    structHash(_signatureParams)
                )
            );
    }

    function structHash(
        ILoanNotary.SignatureParams memory _signatureParams
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash(
                        _signatureParams.collateralAddress,
                        _signatureParams.collateralId
                    ),
                    msg.sender,
                    _signatureParams.collateralNonce
                )
            );
    }

    function typeHash(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (bytes32) {
        return
            IERC721(_collateralAddress).ownerOf(_collateralId) == msg.sender
                ? _initLoanContract__typeHash0
                : _initLoanContract__typeHash1;
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

    // function prefixed(bytes32 _hash) public pure returns (bytes32) {
    //     return
    //         keccak256(
    //             abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    //         );
    // }

    function splitSignature(
        bytes memory _signature
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}
