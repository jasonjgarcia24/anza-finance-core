// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LibOfficerRoles {
    bytes32 public constant _ADMIN_ = keccak256("ADMIN");
    bytes32 public constant _FACTORY_ = keccak256("FACTORY");
    bytes32 public constant _LOAN_CONTRACT_ = keccak256("LOAN_CONTRACT");
    bytes32 public constant _OWNER_ = keccak256("OWNER");
    bytes32 public constant _TREASURER_ = keccak256("TREASURER");
    bytes32 public constant _COLLECTOR_ = keccak256("COLLECTOR");
    bytes32 public constant _DEBT_STOREFRONT_ = keccak256("DEBT_STOREFRONT");
}

library LibLoanContractSigning {
    function recoverSigner(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }

    function prefixed(bytes32 _hash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

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

library LibLoanContractIndexer {
    function getBorrowerTokenId(uint256 _debtId) public pure returns (uint256) {
        return (2 * _debtId) + 1;
    }

    function getLenderTokenId(uint256 _debtId) public pure returns (uint256) {
        return (2 * _debtId);
    }
}
