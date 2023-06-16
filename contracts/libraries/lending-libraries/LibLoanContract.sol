// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@abdk-libraries/ABDKMath64x64.sol";

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
