// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

abstract contract LoanSigningUtils {
    function _recoverSigner(
        uint256 _principal,
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 _message = __prefixed(
            keccak256(
                abi.encode(
                    _principal,
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
