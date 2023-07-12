// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_UINT64_MAX_, _UINT32_MAX_} from "@universal-numbers/StdNumbers.sol";

bytes4 constant _OVERFLOW_CAST_SELECTOR_ = 0x94c4b548; // bytes4(keccak256("OverlflowCast()"))

library TypeUtils {
    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64 _value) {
        assembly {
            if gt(value, _UINT64_MAX_) {
                mstore(0x20, _OVERFLOW_CAST_SELECTOR_)
                revert(0x20, 0x04)
            }

            _value := value
        }
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 _value) {
        assembly {
            if gt(value, _UINT32_MAX_) {
                mstore(0x20, _OVERFLOW_CAST_SELECTOR_)
                revert(0x20, 0x04)
            }

            _value := value
        }
    }

    /**
     * @dev Validates that the input value fits into a uint32.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function verifyUint32(uint256 value) internal pure {
        assembly {
            if gt(value, _UINT32_MAX_) {
                mstore(0x20, _OVERFLOW_CAST_SELECTOR_)
                revert(0x20, 0x04)
            }
        }
    }
}
