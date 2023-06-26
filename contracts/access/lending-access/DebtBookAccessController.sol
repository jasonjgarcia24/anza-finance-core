// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {_ADMIN_} from "@lending-constants/LoanContractRoles.sol";
import {_INVALID_ADDRESS_ERROR_ID_} from "@custom-errors/StdAccessErrors.sol";

import {IDebtBookAccessController} from "./interfaces/IDebtBookAccessController.sol";
import {IAnzaToken} from "@tokens-interfaces/IAnzaToken.sol";
import {ICollateralVault} from "@services-interfaces/ICollateralVault.sol";

abstract contract DebtBookAccessController {
    IAnzaToken internal _anzaToken;
    ICollateralVault internal _collateralVault;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IDebtBookAccessController).interfaceId;
    }

    /**
     * Returns the Anza Token contract address.
     */
    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    /**
     * Returns the Collateral Vault contract address.
     */
    function collateralVault() external view returns (address) {
        return address(_collateralVault);
    }

    /**
     * Call to set the Anza Token contract.
     *
     * @param _anzaTokenAddress The address of the Anza Token contract.
     */
    function setAnzaToken(address _anzaTokenAddress) public virtual;

    /**
     * Call to set the Collateral Vault contract.
     *
     * @param _collateralVaultAddress The address of the Collateral Vault
     * contract.
     */
    function setCollateralVault(address _collateralVaultAddress) public virtual;

    /**
     * Sets the Anza Token contract.
     *
     * @param _anzaTokenAddress The address of the Anza Token contract.
     */
    function _setAnzaToken(address _anzaTokenAddress) internal {
        __verifyAddress(_anzaTokenAddress);

        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    /**
     * Sets the Collateral Vault contract.
     *
     * @param _collateralVaultAddress The address of the Collateral Vault contract.
     */
    function _setCollateralVault(address _collateralVaultAddress) internal {
        __verifyAddress(_collateralVaultAddress);

        _collateralVault = ICollateralVault(_collateralVaultAddress);
    }

    function __verifyAddress(address _account) private pure {
        assembly {
            if iszero(_account) {
                mstore(0x20, _INVALID_ADDRESS_ERROR_ID_)
                revert(0x20, 0x04)
            }
        }
    }
}
