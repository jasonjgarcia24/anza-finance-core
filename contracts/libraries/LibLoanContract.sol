// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../abdk-libraries-solidity/ABDKMath64x64.sol";
import {LibLoanContractPackMappings as PackMappings} from "./LibLoanContractConstants.sol";

// library LibOfficerRoles {
//     bytes32 public constant ADMIN = keccak256("ADMIN");
//     bytes32 public constant FACTORY = keccak256("FACTORY");
//     bytes32 public constant LOAN_CONTRACT = keccak256("LOAN_CONTRACT");
//     bytes32 public constant OWNER = keccak256("OWNER");
//     bytes32 public constant TREASURER = keccak256("TREASURER");
//     bytes32 public constant COLLECTOR = keccak256("COLLECTOR");
//     bytes32 public constant DEBT_STOREFRONT = keccak256("DEBT_STOREFRONT");
//     bytes32 public constant CLOSED_BIN = keccak256("CLOSED_BIN");
// }

library LibLoanContractSigning {
    struct ContractTerms {
        uint8 firInterval;
        uint8 fixedInterestRate;
        uint128 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
        uint8 lenderRoyalties;
    }

    function createContractTerms(
        ContractTerms memory _terms
    ) public pure returns (bytes32 _contractTerms) {
        uint8 _firInterval = _terms.firInterval;
        uint8 _fixedInterestRate = _terms.fixedInterestRate;
        uint128 _principal = _terms.principal;
        uint32 _gracePeriod = _terms.gracePeriod;
        uint32 _duration = _terms.duration;
        uint32 _termsExpiry = _terms.termsExpiry;
        uint8 _lenderRoyalties = _terms.lenderRoyalties;

        assembly {
            mstore(0x20, _firInterval)
            mstore(0x1f, _fixedInterestRate)
            mstore(0x1d, _principal)
            mstore(0x0d, _gracePeriod)
            mstore(0x09, _duration)
            mstore(0x05, _termsExpiry)
            mstore(0x01, _lenderRoyalties)

            _contractTerms := mload(0x20)
        }
    }

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

library LibLoanContractInterest {
    function compoundWithTopoff(
        uint256 _principal,
        uint256 _ratio,
        uint256 _n
    ) public pure returns (uint256) {
        return
            compound(_principal, _ratio, _n) + topoff(_principal, _ratio, _n);
    }

    function compound(
        uint256 _principal,
        uint256 _ratio,
        uint256 _n
    ) public pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(_ratio, 100)
                    ),
                    _n
                ),
                _principal
            );
    }

    function pow(int128 _x, uint256 _n) public pure returns (int128) {
        int128 _r = ABDKMath64x64.fromUInt(1);

        while (_n > 0) {
            if (_n % 2 == 1) {
                _r = ABDKMath64x64.mul(_r, _x);
                _n -= 1;
            } else {
                _x = ABDKMath64x64.mul(_x, _x);
                _n /= 2;
            }
        }

        return _r;
    }

    // Topoff to account for small inaccuracies in compound calculations
    function topoff(
        uint256 _totalDebt,
        uint256 _fixedInterestRate,
        uint256 _firIntervals
    ) public pure returns (uint256) {
        return
            _fixedInterestRate == 100 ? 0 : _fixedInterestRate >= 10
                ? _firIntervals == 1 && _totalDebt >= 10
                    ? 1
                    : _totalDebt >= 1000
                    ? (_totalDebt / (10 ** 21)) >= 1 ? 10 : 1
                    : 0
                : _fixedInterestRate == 1
                ? _firIntervals == 1 && _totalDebt >= 100
                    ? (_totalDebt / (10 ** 21)) >= 1 ? 10 : 1
                    : 0
                : 0;
    }
}
