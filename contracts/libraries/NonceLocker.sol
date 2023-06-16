// SPDX-Licencse-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title NonceLocker
 *
 * @dev The NonceLocker library is used to prevent reentrancy and replay attacks.
 * The library is used to create a single nonce that can only be accessed once by
 * the nonce publisher for the set category. The contract utilizing this library
 * should use the Nonce struct within an array to have multiple nonces.
 *
 * Example:
 *
 *  contract MyContract {
 *      using NonceLocker for NonceLocker.Nonce;
 *
 *      NonceLocker.Nonce[] internal _nonces;
 *      ...
 *  }
 *
 */
library NonceLocker {
    error LockedNonce();
    error InvalidNoncePublisher();
    error InvalidNonceCategory();

    /**
     * Nonce is a struct that represents a one-time access lock.
     *
     * @notice The Nonce struct is used to prevent reentrancy attacks. The
     * nonce fields should never be directly accessed. Instead, use this
     * library's functions.
     *
     * @param __publisher The address that is allowed to access the nonce.
     * @param __category The category of the nonce.
     * @param __lock The flag that indicates whether the nonce has been locked.
     */
    struct Nonce {
        address __publisher;
        uint8 __category;
        bool __locked;
    }

    /**
     * Creates a new Nonce struct that is unlocked.
     *
     * @param _publisher The address that is allowed to access the nonce.
     * @param _category The category of the nonce.
     *
     * @return The unlocked Nonce struct.
     */
    function spawn(
        address _publisher,
        uint8 _category
    ) internal pure returns (Nonce memory) {
        return
            Nonce({
                __publisher: _publisher,
                __category: _category,
                __locked: false
            });
    }

    /**
     * Creates a new Nonce struct that is locked.
     *
     * @param _publisher The address that is allowed to access the nonce.
     * @param _category The category of the nonce.
     *
     * @return The locked Nonce struct.
     */
    function ruin(
        address _publisher,
        uint8 _category
    ) internal pure returns (Nonce memory) {
        return
            Nonce({
                __publisher: _publisher,
                __category: _category,
                __locked: true
            });
    }

    /**
     * Locks the nonce.
     *
     * @param _nonce The nonce to lock.
     */
    function oneTimeAccess(Nonce storage _nonce, uint8 _category) internal {
        // If the nonce is locked, then the publisher has already accessed it.
        if (_nonce.__locked) revert LockedNonce();

        // If the publisher is not the sender, do not allow access.
        if (_nonce.__publisher != msg.sender) revert InvalidNoncePublisher();

        // If the category is not the same, do not allow access.
        if (_nonce.__category != _category) revert InvalidNonceCategory();

        _nonce.__locked = true;
    }
}
