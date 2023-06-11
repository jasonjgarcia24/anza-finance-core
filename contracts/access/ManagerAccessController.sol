// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../../lib/forge-std/src/console.sol";

import "../domain/LoanContractRoles.sol";

import {IManagerAccessController} from "../interfaces/IManagerAccessController.sol";
import {IAnzaToken} from "../interfaces/IAnzaToken.sol";
import {ICollateralVault} from "../interfaces/ICollateralVault.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract ManagerAccessController is
    IManagerAccessController,
    AccessControl
{
    address internal _loanTreasurerAddress;

    IAnzaToken internal _anzaToken;
    ICollateralVault internal _collateralVault;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(IManagerAccessController).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }

    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    function loanTreasurer() external view returns (address) {
        return _loanTreasurerAddress;
    }

    function collateralVault() external view returns (address) {
        return address(_collateralVault);
    }

    function setAnzaToken(
        address _anzaTokenAddress
    ) external onlyRole(_ADMIN_) {
        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    function setLoanTreasurer(
        address _loanTreasurerAddress_
    ) external onlyRole(_ADMIN_) {
        __setLoanTreasurer(_loanTreasurerAddress_);
    }

    function setCollateralVault(
        address _collateralVaultAddress
    ) external onlyRole(_ADMIN_) {
        _collateralVault = ICollateralVault(_collateralVaultAddress);
    }

    function _grantRole(
        bytes32 _role,
        address _account
    ) internal virtual override {
        (_role == _TREASURER_)
            ? __setLoanTreasurer(_account)
            : super._grantRole(_role, _account);
    }

    function __setLoanTreasurer(address _loanTreasurerAddress_) private {
        _revokeRole(_TREASURER_, _loanTreasurerAddress_);
        super._grantRole(_TREASURER_, _loanTreasurerAddress_);

        _loanTreasurerAddress = _loanTreasurerAddress_;
    }
}
