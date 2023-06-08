// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../../lib/forge-std/src/console.sol";

import "../domain/LoanContractRoles.sol";

import {ITreasureyAccessController} from "../interfaces/ITreasureyAccessController.sol";
import {ILoanContract} from "../interfaces/ILoanContract.sol";
import {ILoanManager} from "../interfaces/ILoanManager.sol";
import {ILoanCodec} from "../interfaces/ILoanCodec.sol";
import {ICollateralVault} from "../interfaces/ICollateralVault.sol";
import {IAnzaToken} from "../interfaces/IAnzaToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract TreasureyAccessController is
    ITreasureyAccessController,
    AccessControl
{
    ILoanContract internal _loanContract;
    ILoanCodec internal _loanCodec;
    ILoanManager internal _loanManager;
    ICollateralVault internal _collateralVault;
    IAnzaToken internal _anzaToken;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_LOAN_CONTRACT_, _ADMIN_);
        _setRoleAdmin(_DEBT_STOREFRONT_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(ITreasureyAccessController).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }

    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    function loanContract() external view returns (address) {
        return address(_loanContract);
    }

    function collateralVault() external view returns (address) {
        return address(_collateralVault);
    }

    function setAnzaToken(
        address _anzaTokenAddress
    ) external onlyRole(_ADMIN_) {
        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    function setLoanContract(
        address _loanContractAddress
    ) external onlyRole(_ADMIN_) {
        __setLoanContract(_loanContractAddress);
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
        if (_role == _LOAN_CONTRACT_) {
            __setLoanContract(_account);
        } else {
            super._grantRole(_role, _account);
        }
    }

    function __setLoanContract(address _loanContractAddress) private {
        _revokeRole(_LOAN_CONTRACT_, address(_loanContract));
        super._grantRole(_LOAN_CONTRACT_, _loanContractAddress);

        _loanContract = ILoanContract(_loanContractAddress);
        _loanCodec = ILoanCodec(_loanContractAddress);
        _loanManager = ILoanManager(_loanContractAddress);
    }
}
