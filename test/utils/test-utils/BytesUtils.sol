// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

library BytesUtils {
    function normalizeBytesMSB(
        bytes[2] memory _values
    ) public pure returns (bytes memory _a, bytes memory _b) {
        if (_values[0].length > _values[1].length) {
            _a = _values[0];
            _b = abi.encodePacked(
                _values[1],
                new bytes(_values[0].length - _values[1].length)
            );
        } else if (_values[1].length > _values[0].length) {
            _a = abi.encodePacked(
                _values[0],
                new bytes(_values[1].length - _values[0].length)
            );
            _b = _values[1];
        }
    }

    function normalizeBytesLSB(
        bytes[2] memory _values
    ) public pure returns (bytes memory _a, bytes memory _b) {
        if (_values[0].length > _values[1].length) {
            _a = _values[0];
            _b = abi.encodePacked(
                new bytes(_values[0].length - _values[1].length),
                _values[1]
            );
        } else if (_values[1].length > _values[0].length) {
            _a = abi.encodePacked(
                new bytes(_values[1].length - _values[0].length),
                _values[0]
            );
            _b = _values[1];
        }
    }
}
