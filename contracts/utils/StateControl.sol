// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.9;

/**
 * @title StateControlUint
 * @dev Provides state controlled uint256 variables.
 *
 * Include with `using StateControl for StateControlUint.Property;`
 */
library StateControlUint {
    struct Property {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function.
        uint256 _value; // default: 0
        uint256 _stateThreshold;
        bool _lock;
    }

    function init(Property storage _property, uint256 _stateThreshold) internal {
        require(!_property._lock, "Initialization is locked.");
        _property._lock = true;

        _property._stateThreshold = _stateThreshold;
    }

    function get(Property storage _property) internal view returns (uint256) {
        return _property._value;
    }

    function set(Property storage _property, uint256 _value, uint256 _state) internal {
        require(__stateController(_property, _state), "Access to change value is denied.");

        unchecked {
            _property._value = _value;
        }
    }

    function __stateController(Property storage _property, uint256 _state) private view returns (bool) {
        return _state <= _property._stateThreshold;
    }
}

/**
 * @title StateControlAddress
 * @dev Provides state controlled address variables.
 *
 * Include with `using StateControl for StateControlAddress.Property;`
 */
library StateControlAddress {
    struct Property {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function.
        address _value; // default: address(0)
        uint256 _stateThreshold;
        bool _lock;
    }

    function init(Property storage _property, uint256 _stateThreshold) internal {
        require(!_property._lock, "Initialization is locked.");
        _property._lock = true;

        _property._stateThreshold = _stateThreshold;
    }

    function get(Property storage _property) internal view returns (address) {
        return _property._value;
    }

    function set(Property storage _property, address _value, uint256 _state) internal {
        require(__stateController(_property, _state), "Access to change value is denied.");

        unchecked {
            _property._value = _value;
        }
    }

    function __stateController(Property storage _property, uint256 _state) private view returns (bool) {
        return _state <= _property._stateThreshold;
    }
}

/**
 * @title StateControlBool
 * @dev Provides state controlled boolean variables.
 *
 * Include with `using StateControl for StateControlBool.Property;`
 */
library StateControlBool {
    struct Property {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function.
        bool _value; // default: false
        uint256 _stateThreshold;
        bool _lock;
    }

    function init(Property storage _property, uint256 _stateThreshold) internal {
        require(!_property._lock, "Init locked.");
        _property._lock = true;

        _property._stateThreshold = _stateThreshold;
    }

    function get(Property storage _property) internal view returns (bool) {
        return _property._value;
    }

    function set(Property storage _property, bool _value, uint256 _state) internal {
        require(__stateController(_property, _state), "Access to change value is denied.");

        unchecked {
            _property._value = _value;
        }
    }

    function __stateController(Property storage _property, uint256 _state) private view returns (bool) {
        return _state <= _property._stateThreshold;
    }
}
