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
    bytes32 public constant _DEBT_STOREFRONT_ = keccak256("DEBT_STOREFRONT");
}

library LibLoanContractTerms {
    /* ------------------------------------------------ *
     *                  Loan States                     *
     * ------------------------------------------------ */
    uint8 private constant _UNDEFINED_STATE_ = 0;
    uint8 private constant _NONLEVERAGED_STATE_ = 1;
    uint8 private constant _UNSPONSORED_STATE_ = 2;
    uint8 private constant _SPONSORED_STATE_ = 3;
    uint8 private constant _FUNDED_STATE_ = 4;
    uint8 private constant _ACTIVE_GRACE_STATE_ = 5;
    uint8 private constant _ACTIVE_STATE_ = 6;
    uint8 private constant _DEFAULT_STATE_ = 7;
    uint8 private constant _COLLECTION_STATE_ = 8;
    uint8 private constant _AUCTION_STATE_ = 9;
    uint8 private constant _AWARDED_STATE_ = 10;
    uint8 private constant _CLOSE_STATE_ = 11;
    uint8 private constant _PAID_STATE_ = 12;

    /* ------------------------------------------------ *
     *           Packed Debt Term Mappings              *
     * ------------------------------------------------ */
    uint256 private constant _LOAN_STATE_MAP_ = 15;
    uint256 private constant _FIR_MAP_ = 4080;
    uint256 private constant _LOAN_START_MASK_ = 4095;
    uint256 private constant _LOAN_START_MAP_ = 17592186040320;
    uint256 private constant _LOAN_CLOSE_MASK_ = 17592186044415;
    uint256 private constant _LOAN_CLOSE_MAP_ = 75557863708322137374720;
    uint256 private constant _BORROWER_MASK_ = 75557863725914323419135;
    uint256 private constant _BORROWER_MAP_ =
        110427941548649020598956093796432407239217743554650627018874473257369600;

    function loanState(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanState) {
        uint8 __loanState;

        assembly {
            __loanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function fixedInterestRate(
        bytes32 _contractTerms
    ) public pure returns (uint256 _fixedInterestRate) {
        bytes32 __fixedInterestRate;

        assembly {
            __fixedInterestRate := and(_contractTerms, _FIR_MAP_)
        }

        unchecked {
            _fixedInterestRate = uint256(__fixedInterestRate >> 4);
        }
    }

    function loanStart(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanStart) {
        uint32 __loanStart;

        assembly {
            __loanStart := shr(12, and(_contractTerms, _LOAN_START_MAP_))
        }

        unchecked {
            _loanStart = __loanStart;
        }
    }

    function loanClose(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanClose) {
        uint32 __loanClose;

        assembly {
            __loanClose := shr(44, and(_contractTerms, _LOAN_CLOSE_MAP_))
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function borrower(
        bytes32 _contractTerms
    ) public pure returns (address _borrower) {
        assembly {
            _borrower := shr(76, and(_contractTerms, _BORROWER_MAP_))
        }
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
