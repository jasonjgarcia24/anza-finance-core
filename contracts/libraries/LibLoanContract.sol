// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../domain/LoanContractFIRIntervals.sol";
import "../domain/LoanContractTermMaps.sol";

import "../abdk-libraries-solidity/ABDKMath64x64.sol";

library LibLoanContractSigning {
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
        uint256 _principal,
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = prefixed(
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

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ecrecover(_message, v, r, s);
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
        uint8 __loanState;

        assembly {
            __loanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function firInterval(
        bytes32 _contractTerms
    ) public pure returns (uint256 _firInterval) {
        uint8 __firInterval;

        assembly {
            __firInterval := shr(
                _FIR_INTERVAL_POS_,
                and(_contractTerms, _FIR_INTERVAL_MAP_)
            )
        }

        unchecked {
            _firInterval = __firInterval;
        }
    }

    function fixedInterestRate(
        bytes32 _contractTerms
    ) public pure returns (uint256 _fixedInterestRate) {
        bytes32 __fixedInterestRate;

        assembly {
            __fixedInterestRate := shr(
                _FIR_POS_,
                and(_contractTerms, _FIR_MAP_)
            )
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
        uint32 __loanStart;

        assembly {
            __loanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )
        }

        unchecked {
            _loanStart = __loanStart;
        }
    }

    function loanDuration(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanDuration) {
        uint32 __loanDuration;

        assembly {
            __loanDuration := shr(
                _LOAN_DURATION_POS_,
                and(_contractTerms, _LOAN_DURATION_MAP_)
            )
        }

        unchecked {
            _loanDuration = __loanDuration;
        }
    }

    function loanCommital(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanCommital) {
        uint32 __loanCommital;

        assembly {
            __loanCommital := shr(
                _COMMITAL_POS_,
                and(_contractTerms, _COMMITAL_MAP_)
            )
        }

        unchecked {
            _loanCommital = __loanCommital;
        }
    }

    function loanCommitalTime(
        bytes32 _contractTerms
    ) public pure returns (uint256) {
        int128 _loanStart = ABDKMath64x64.fromUInt(loanStart(_contractTerms));
        int128 _loanDuration = ABDKMath64x64.fromUInt(
            loanDuration(_contractTerms)
        );
        int128 _ratio = ABDKMath64x64.divu(loanCommital(_contractTerms), 100);
        int128 _commitalPeriod = ABDKMath64x64.mul(_loanDuration, _ratio);
        int128 _commitalTime = ABDKMath64x64.add(_loanStart, _commitalPeriod);

        return ABDKMath64x64.toUInt(_commitalTime);
    }

    function isFixed(
        bytes32 _contractTerms
    ) public pure returns (uint256 _isFixed) {
        uint32 __isFixed;

        assembly {
            __isFixed := shr(
                _IS_FIXED_POS_,
                and(_contractTerms, _IS_FIXED_MAP_)
            )
        }

        unchecked {
            _isFixed = __isFixed;
        }
    }

    function loanClose(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanClose) {
        uint32 __loanClose;

        assembly {
            __loanClose := add(
                shr(_LOAN_START_POS_, and(_contractTerms, _LOAN_START_MAP_)),
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function lenderRoyalties(
        bytes32 _contractTerms
    ) public pure returns (uint256 _lenderRoyalties) {
        assembly {
            _lenderRoyalties := shr(
                _LENDER_ROYALTIES_POS_,
                and(_contractTerms, _LENDER_ROYALTIES_MAP_)
            )
        }
    }

    function activeLoanCount(
        bytes32 _contractTerms
    ) public pure returns (uint256 _activeLoanCount) {
        uint8 __activeLoanCount;

        assembly {
            __activeLoanCount := shr(
                _LOAN_COUNT_POS_,
                and(_contractTerms, _LOAN_COUNT_MAP_)
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
