// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPaymentBookAccessController} from "./interfaces/IPaymentBookAccessController.sol";
import {IAnzaToken} from "@tokens-interfaces/IAnzaToken.sol";

abstract contract PaymentBookAccessController is IPaymentBookAccessController {
    IAnzaToken internal _anzaToken;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IPaymentBookAccessController).interfaceId;
    }

    /**
     * Returns the Anza Token contract address.
     *
     * @return The Anza Token contract address.
     */
    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    /**
     * Call to set the Anza Token contract.
     *
     * @param _anzaTokenAddress The address of the Anza Token contract.
     *
     * @dev This function must be overriden by the inheriting contract.
     */
    function setAnzaToken(address _anzaTokenAddress) public virtual;

    /**
     * Sets the Anza Token contract.
     *
     * @dev This function is called by the inheriting contract.
     *
     * @param _anzaTokenAddress The address of the Anza Token contract.
     */
    function _setAnzaToken(address _anzaTokenAddress) internal {
        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }
}
