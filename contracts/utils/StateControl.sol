// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { LibContractStates as States } from "../social/libraries/LibContractMaster.sol";

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
        uint256 _lock; // default: 0 (uint for gas saving)
        States.LoanState _stateThreshold; // default: 0
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {checkState}.
     *
     */
    function onlyState(Property storage _property, States.LoanState _state) public view {
        StateControlUtils.checkState(_property, _state);
    }

    /**
     * @dev Function that initializes the state controlled variable.
     * 
     * Requirements:
     * - The property lock must be unset (equal to 0).
     *
     */
    function init(
        Property storage _property,
        uint256 _value,
        States.LoanState _stateThreshold
    ) public {
        require(_property._lock == 0, "Initialization is locked.");
        _property._lock++;

        unchecked {
            _property._stateThreshold = _stateThreshold;
            _property._value = _value;
        }
    }

    /**
     * @dev Function that gets the state controlled variable's `_value`.
     * 
     * Requirements:
     * - The property lock must be set (equal to 1).
     *
     */
    function get(Property storage _property) public view returns (uint256) {
        require(_property._lock == 1, "State controller not initialized.");

        return _property._value;
    }

    /**
     * @dev Function that sets the state controlled variable's `_value`.
     * 
     * Requirements:
     * - The `_state` must be no greater than the property statethreshold {StateControlUtils.checkState}.
     * - The property lock must be set (equal to 1).
     *
     */
    function set(
        Property storage _property,
        uint256 _value,
        States.LoanState _state
    ) public {
        onlyState(_property, _state);
        require(_property._lock == 1, "State controller not initialized.");

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
        uint256 _lock; // default: 0 (uint for gas saving)
        States.LoanState _stateThreshold; // default: 0
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {checkState}.
     *
     */
    function onlyState(Property storage _property, States.LoanState _state) public view {
        StateControlUtils.checkState(_property, _state);
    }

    /**
     * @dev Function that initializes the state controlled variable.
     * 
     * Requirements:
     * - The property lock must be unset (equal to 0).
     *
     */
    function init(
        Property storage _property,
        address _value,
        States.LoanState _stateThreshold
    ) public {
        require(_property._lock == 0, "Initialization is locked.");
        _property._lock++;

        unchecked {
            _property._stateThreshold = _stateThreshold;
            _property._value = _value;
        }
    }

    /**
     * @dev Function that gets the state controlled variable's `_value`.
     * 
     * Requirements:
     * - The property lock must be set (equal to 1).
     *
     */
    function get(Property storage _property) public view returns (address) {
        require(_property._lock == 1, "State controller not initialized.");

        return _property._value;
    }

    /**
     * @dev Function that sets the state controlled variable's `_value`.
     * 
     * Requirements:
     * - The `_state` must be no greater than the property statethreshold {StateControlUtils.checkState}.
     * - The property lock must be set (equal to 1).
     *
     */
    function set(
        Property storage _property,
        address _value,
        States.LoanState _state
    ) public {
        onlyState(_property, _state);
        require(_property._lock == 1, "State controller not initialized.");

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
        uint256 _lock; // default: 0 (uint for gas saving)
        States.LoanState _stateThreshold; // default: 0
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {checkState}.
     *
     */
    function onlyState(Property storage _property, States.LoanState _state) public view {
        StateControlUtils.checkState(_property, _state);
    }


    /**
     * @dev Function that initializes the state controlled variable.
     * 
     * Requirements:
     * - The property lock must be unset (equal to 0).
     *
     */
    function init(
        Property storage _property,
        bool _value,
        States.LoanState _stateThreshold
    ) public {
        require(_property._lock == 0, "Init locked.");
        _property._lock++;

        unchecked {
            _property._stateThreshold = _stateThreshold;
            _property._value = _value;
        }
    }

    /**
     * @dev Function that gets the state controlled variable's `_value`.
     * 
     * Requirements:
     * - The property lock must be set (equal to 1).
     *
     */
    function get(Property storage _property) public view returns (bool) {
        require(_property._lock == 1, "State controller not initialized.");

        return _property._value;
    }

    /**
     * @dev Function that sets the state controlled variable's `_value`.
     * 
     * Requirements:
     * - The `_state` must be no greater than the property statethreshold {StateControlUtils.checkState}.
     * - The property lock must be set (equal to 1).
     *
     */
    function set(
        Property storage _property,
        bool _value,
        States.LoanState _state
    ) public {
        onlyState(_property, _state);
        require(_property._lock == 1, "State controller not initialized.");

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
    function checkState(
        StateControlUint.Property storage _property,
        States.LoanState _state
    ) public view {
        require(
            isActive(_state, _property._stateThreshold),
            "Access to change value is denied."
        );
    }

    /**
     * @dev Revert with a revert message if the state threshold of`_property` is
     * beyond `_state`.
     *
     */
    function checkState(
        StateControlAddress.Property storage _property,
        States.LoanState _state
    ) public view {
        require(
            isActive(_state, _property._stateThreshold),
            "Access to change value is denied."
        );
    }

    /**
     * @dev Revert with a revert message if the state threshold of`_property` is
     * beyond `_state`.
     *
     */
    function checkState(
        StateControlBool.Property storage _property,
        States.LoanState _state
    ) public view {
        require(
            isActive(_state, _property._stateThreshold),
            "Access to change value is denied."
        );
    }

    /**
     * @dev Return if the state threshold of`_property` is beyond `_state`.
     *
     */
    function isActive(States.LoanState _state, States.LoanState _stateThreshold)
        public
        pure
        returns (bool)
    {
        return _state <= _stateThreshold;
    }
}
