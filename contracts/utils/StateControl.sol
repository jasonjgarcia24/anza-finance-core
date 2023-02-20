// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {LibLoanContractStates as States} from "../utils/LibLoanContractStates.sol";

error InitializationLocked();
error ControllerNotInitialized();
error ValueChangeDenied();

/**
 * @title StateControlUint256
 * @dev Provides state controlled uint256 variables.
 *
 * Include with `using StateControl for StateControlUint256.Property;`
 */
library StateControlUint256 {
    struct Property {
        // These variables should never be directly accessed by users of the library:
        // interactions must be restricted to the library's function.
        uint256 _value; // default: 0
        uint256 _lock; // default: 0
        States.LoanState _stateThreshold; // default: 0
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {checkState}.
     *
     */
    function onlyActiveState(
        Property storage _property,
        States.LoanState _state
    ) public view {
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
        if (_property._lock == 1) revert InitializationLocked();
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
        if (_property._lock == 0) revert ControllerNotInitialized();

        return _property._value;
    }

    /**
     * @dev Function that gets the state controlled variable's `_stateThreshold`.
     *
     * Requirements:
     * - The property lock must be set (equal to 1).
     *
     */
    function getThreshold(Property storage _property)
        public
        view
        returns (States.LoanState)
    {
        if (_property._lock == 0) revert ControllerNotInitialized();

        return _property._stateThreshold;
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
        onlyActiveState(_property, _state);
        if (_property._lock == 0) revert ControllerNotInitialized();

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
        // These variables should never be directly accessed by users of the library:
        // interactions must be restricted to the library's function.
        address _value; // default: address(0)
        uint256 _lock; // default: 0
        States.LoanState _stateThreshold; // default: 0
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {checkState}.
     *
     */
    function onlyActiveState(
        Property storage _property,
        States.LoanState _state
    ) public view {
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
        if (_property._lock == 1) revert InitializationLocked();
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
        if (_property._lock == 0) revert ControllerNotInitialized();

        return _property._value;
    }

    /**
     * @dev Function that gets the state controlled variable's `_stateThreshold`.
     *
     * Requirements:
     * - The property lock must be set (equal to 1).
     *
     */
    function getThreshold(Property storage _property)
        public
        view
        returns (States.LoanState)
    {
        if (_property._lock == 0) revert ControllerNotInitialized();

        return _property._stateThreshold;
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
        onlyActiveState(_property, _state);
        if (_property._lock == 0) revert ControllerNotInitialized();

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
        // These variables should never be directly accessed by users of the library:
        // interactions must be restricted to the library's function.
        bool _value; // default: false
        uint256 _lock; // default: 0
        States.LoanState _stateThreshold; // default: 0
    }

    /**
     * @dev Function that checks that a state controlled variable does not violate its
     * state threshold. Reverts with a message described in {checkState}.
     *
     */
    function onlyActiveState(
        Property storage _property,
        States.LoanState _state
    ) public view {
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
        if (_property._lock == 1) revert InitializationLocked();
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
        if (_property._lock == 0) revert ControllerNotInitialized();

        return _property._value;
    }

    /**
     * @dev Function that gets the state controlled variable's `_stateThreshold`.
     *
     * Requirements:
     * - The property lock must be set (equal to 1).
     *
     */
    function getThreshold(Property storage _property)
        public
        view
        returns (States.LoanState)
    {
        if (_property._lock == 0) revert ControllerNotInitialized();

        return _property._stateThreshold;
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
        onlyActiveState(_property, _state);
        if (_property._lock == 0) revert ControllerNotInitialized();

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
     */
    function checkState(
        StateControlUint256.Property storage _property,
        States.LoanState _state
    ) public view {
        if (!isActive(_state, _property._stateThreshold))
            revert ValueChangeDenied();
    }

    /**
     * @dev Revert with a revert message if the state threshold of`_property` is
     * beyond `_state`.
     */
    function checkState(
        StateControlAddress.Property storage _property,
        States.LoanState _state
    ) public view {
        if (!isActive(_state, _property._stateThreshold))
            revert ValueChangeDenied();
    }

    /**
     * @dev Revert with a revert message if the state threshold of`_property` is
     * beyond `_state`.
     */
    function checkState(
        StateControlBool.Property storage _property,
        States.LoanState _state
    ) public view {
        if (!isActive(_state, _property._stateThreshold))
            revert ValueChangeDenied();
    }

    /**
     * @dev Return if the state threshold of`_property` is beyond `_state`.
     */
    function isActive(States.LoanState _state, States.LoanState _stateThreshold)
        public
        pure
        returns (bool)
    {
        return _state <= _stateThreshold;
    }
}
