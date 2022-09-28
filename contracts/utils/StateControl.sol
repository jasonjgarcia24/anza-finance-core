// SPDX-License-Identifier: MIT
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
        uint256 _stateThreshold; // default: 0
        bool _lock; // default: false
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {_checkState}.
     *
     */
    function onlyState(Property storage _property, uint256 _state) public view {
        StateControlUtils._checkState(_property, _state);
    }

    function init(Property storage _property, uint256 _stateThreshold)
        internal
    {
        require(!_property._lock, "Initialization is locked.");
        _property._lock = true;

        unchecked {
            _property._stateThreshold = _stateThreshold;
        }
    }

    function init(
        Property storage _property,
        uint256 _value,
        uint256 _stateThreshold
    ) internal {
        require(!_property._lock, "Initialization is locked.");
        _property._lock = true;

        unchecked {
            _property._stateThreshold = _stateThreshold;
            _property._value = _value;
        }
    }

    function get(Property storage _property) internal view returns (uint256) {
        require(_property._lock, "State controller not initialized.");

        return _property._value;
    }

    function set(
        Property storage _property,
        uint256 _value,
        uint256 _state
    ) internal {
        onlyState(_property, _state);
        require(_property._lock, "State controller not initialized.");

        unchecked {
            _property._value = _value;
        }
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
        uint256 _stateThreshold; // default: 0
        bool _lock; // default: false
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {_checkState}.
     *
     */
    function onlyState(Property storage _property, uint256 _state) public view {
        StateControlUtils._checkState(_property, _state);
    }

    function init(Property storage _property, uint256 _stateThreshold)
        internal
    {
        require(!_property._lock, "Initialization is locked.");
        _property._lock = true;

        unchecked {
            _property._stateThreshold = _stateThreshold;
        }
    }

    function init(
        Property storage _property,
        address _value,
        uint256 _stateThreshold
    ) internal {
        require(!_property._lock, "Initialization is locked.");
        _property._lock = true;

        unchecked {
            _property._stateThreshold = _stateThreshold;
            _property._value = _value;
        }
    }

    function get(Property storage _property) internal view returns (address) {
        return _property._value;
    }

    function set(
        Property storage _property,
        address _value,
        uint256 _state
    ) internal {
        onlyState(_property, _state);
        require(_property._lock, "State controller not initialized.");

        unchecked {
            _property._value = _value;
        }
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
        uint256 _stateThreshold; // default: 0
        bool _lock; // default: false
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {_checkState}.
     *
     */
    function onlyState(Property storage _property, uint256 _state) public view {
        StateControlUtils._checkState(_property, _state);
    }

    function init(Property storage _property, uint256 _stateThreshold)
        internal
    {
        require(!_property._lock, "Init locked.");
        _property._lock = true;

        unchecked {
            _property._stateThreshold = _stateThreshold;
        }
    }

    function init(
        Property storage _property,
        bool _value,
        uint256 _stateThreshold
    ) internal {
        require(!_property._lock, "Init locked.");
        _property._lock = true;

        unchecked {
            _property._stateThreshold = _stateThreshold;
            _property._value = _value;
        }
    }

    function get(Property storage _property) internal view returns (bool) {
        return _property._value;
    }

    function set(
        Property storage _property,
        bool _value,
        uint256 _state
    ) internal {
        onlyState(_property, _state);
        require(_property._lock, "State controller not initialized.");

        unchecked {
            _property._value = _value;
        }
    }
}

/**
 * @title StateControlUtils
 * @dev Provides state controlled library standard functions.
 *
 */
library StateControlUtils {
    /**
     * @dev Revert with a revert message if the state threshold of`_property` is
     * beyond `_state`.
     *
     */
    function _checkState(
        StateControlUint.Property storage _property,
        uint256 _state
    ) internal view {
        require(
            _isActive(_state, _property._stateThreshold),
            "Access to change value is denied."
        );
    }

    /**
     * @dev Revert with a revert message if the state threshold of`_property` is
     * beyond `_state`.
     *
     */
    function _checkState(
        StateControlAddress.Property storage _property,
        uint256 _state
    ) internal view {
        require(
            _isActive(_state, _property._stateThreshold),
            "Access to change value is denied."
        );
    }

    /**
     * @dev Revert with a revert message if the state threshold of`_property` is
     * beyond `_state`.
     *
     */
    function _checkState(
        StateControlBool.Property storage _property,
        uint256 _state
    ) internal view {
        require(
            _isActive(_state, _property._stateThreshold),
            "Access to change value is denied."
        );
    }

    /**
     * @dev Return if the state threshold of`_property` is beyond `_state`.
     *
     */
    function _isActive(uint256 _state, uint256 _stateThreshold)
        internal
        pure
        returns (bool)
    {
        return _state <= _stateThreshold;
    }
}
