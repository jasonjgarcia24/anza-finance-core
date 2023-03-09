// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../abdk-libraries-solidity/ABDKMath64x64.sol";
import "../interfaces/ILoanContract.sol";
import {LibLoanContractStates as States} from "../utils/LibLoanContractStates.sol";
import "../utils/StateControl.sol";
import "../utils/BlockTime.sol";
import "hardhat/console.sol";

library LibOfficerRoles {
    bytes32 public constant _ADMIN_ = keccak256("ADMIN");
    bytes32 public constant _FACTORY_ = keccak256("FACTORY");
    bytes32 public constant _LOAN_CONTRACT_ = keccak256("LOAN_CONTRACT");
    bytes32 public constant _OWNER_ = keccak256("OWNER");
    bytes32 public constant _TREASURER_ = keccak256("TREASURER");
    bytes32 public constant _COLLECTOR_ = keccak256("COLLECTOR");
}

library LibLoanContractMetadata {
    struct TokenData {
        address collateralAddress; // [0..159] - 160
        uint256 collateralId; // [160..223] - 64
        uint256 principal; // [224..287] - 64
        uint256 fixedInterestRate; // [288..295] - 8
        uint256 duration; // [296..359] - 64
        uint256 unpaidBalance;
        uint256 withdrawableBalance;
    }
}

library LibLoanContractInit {
    using StateControlUint256 for StateControlUint256.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

    function parseParticipants(
        LibLoanContractMetadata.TokenData storage _token,
        address _arbiter
    ) public returns (address[2] memory) {
        // IERC721 _collateralToken = IERC721(_token.collateralAddress);
        // _collateralToken.safeTransferFrom(
        //     _borrower,
        //     _arbiter,
        //     _token.collateralId,
        //     abi.encodePacked(_token.collateralAddress)
        // );
        // } else {
        //     require(
        //         msg.value == _principal,
        //         "msg.value must match loan principal"
        //     );
        // }
        // return [
        //     _callerIsOwner ? _owner : address(this), // borrower
        //     !_callerIsOwner ? _caller : address(this) // lender
        // ];
    }

    function depositCollateral(
        address _to,
        address _collateralAddress,
        uint256 _collateralId
    ) public {
        IERC721 _collateralToken = IERC721(_collateralAddress);
        address _owner = _collateralToken.ownerOf(_collateralId);

        _collateralToken.safeTransferFrom(_owner, _to, _collateralId, "");
    }
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

    function prefixed(bytes32 _hash) internal pure returns (bytes32) {
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
