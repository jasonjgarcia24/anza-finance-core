// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {LibLoanContractPackMappings as PackMappings} from "./LibLoanContractConstants.sol";

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

library LibLoanContractTerms {
    function loanState(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanState) {
        uint256 _loanStateMap = PackMappings._LOAN_STATE_MAP_;
        uint8 __loanState;

        assembly {
            __loanState := and(_contractTerms, _loanStateMap)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function firInterval(
        bytes32 _contractTerms
    ) public pure returns (uint256 _firInterval) {
        uint256 _firIntervalPos = PackMappings._FIR_INTERVAL_POS_;
        uint256 _firIntervalMap = PackMappings._FIR_INTERVAL_MAP_;
        uint8 __firInterval;

        assembly {
            __firInterval := shr(
                _firIntervalPos,
                and(_contractTerms, _firIntervalMap)
            )
        }

        unchecked {
            _firInterval = __firInterval;
        }
    }

    function fixedInterestRate(
        bytes32 _contractTerms
    ) public pure returns (uint256 _fixedInterestRate) {
        uint256 _firPos = PackMappings._FIR_POS_;
        uint256 _firMap = PackMappings._FIR_MAP_;
        bytes32 __fixedInterestRate;

        assembly {
            __fixedInterestRate := shr(_firPos, and(_contractTerms, _firMap))
        }

        unchecked {
            _fixedInterestRate = uint256(__fixedInterestRate);
        }
    }

    function loanLastChecked(
        bytes32 _contractTerms
    ) external pure returns (uint256) {
        return loanStart(_contractTerms);
    }

    function loanStart(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanStart) {
        uint256 _loanStartPos = PackMappings._LOAN_START_POS_;
        uint256 _loanStartMap = PackMappings._LOAN_START_MAP_;
        uint32 __loanStart;

        assembly {
            __loanStart := shr(
                _loanStartPos,
                and(_contractTerms, _loanStartMap)
            )
        }

        unchecked {
            _loanStart = __loanStart;
        }
    }

    function loanDuration(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanDuration) {
        uint256 _loanDurationPos = PackMappings._LOAN_DURATION_POS_;
        uint256 _loanDurationMap = PackMappings._LOAN_DURATION_MAP_;
        uint32 __loanDuration;

        assembly {
            __loanDuration := shr(
                _loanDurationPos,
                and(_contractTerms, _loanDurationMap)
            )
        }

        unchecked {
            _loanDuration = __loanDuration;
        }
    }

    function loanClose(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanClose) {
        uint256 _loanStartPos = PackMappings._LOAN_START_POS_;
        uint256 _loanStartMap = PackMappings._LOAN_START_MAP_;
        uint256 _loanDurationPos = PackMappings._LOAN_DURATION_POS_;
        uint256 _loanDurationMap = PackMappings._LOAN_DURATION_MAP_;
        uint32 __loanClose;

        assembly {
            __loanClose := add(
                shr(_loanStartPos, and(_contractTerms, _loanStartMap)),
                shr(_loanDurationPos, and(_contractTerms, _loanDurationMap))
            )
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function borrower(
        bytes32 _contractTerms
    ) public pure returns (address _borrower) {
        uint256 _borrowerPos = PackMappings._BORROWER_POS_;
        uint256 _borrowerMap = PackMappings._BORROWER_MAP_;

        assembly {
            _borrower := shr(_borrowerPos, and(_contractTerms, _borrowerMap))
        }
    }

    function lenderRoyalties(
        bytes32 _contractTerms
    ) public pure returns (uint256 _lenderRoyalties) {
        uint256 _lenderRoyaltiesPos = PackMappings._LENDER_ROYALTIES_POS_;
        uint256 _lenderRoyaltiesMap = PackMappings._LENDER_ROYALTIES_MAP_;

        assembly {
            _lenderRoyalties := shr(
                _lenderRoyaltiesPos,
                and(_contractTerms, _lenderRoyaltiesMap)
            )
        }
    }

    function activeLoanCount(
        bytes32 _contractTerms
    ) public pure returns (uint256 _activeLoanCount) {
        uint256 _loanCountPos = PackMappings._LOAN_COUNT_POS_;
        uint256 _loanCountMap = PackMappings._LOAN_COUNT_MAP_;
        uint8 __activeLoanCount;

        assembly {
            __activeLoanCount := shr(
                _loanCountPos,
                and(_contractTerms, _loanCountMap)
            )
        }

        unchecked {
            _activeLoanCount = __activeLoanCount;
        }
    }
}
