// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import {_DEBT_MARKET_} from "@market-constants/AnzaDebtMarketRoles.sol";

import {ITreasureyAccessController} from "@lending-access/interfaces/ITreasureyAccessController.sol";
import {IDebtBook} from "@lending-databases/interfaces/IDebtBook.sol";
import {IDebtTerms} from "@lending-databases/interfaces/IDebtTerms.sol";
import {ILoanManager} from "@lending-interfaces/ILoanManager.sol";
import {ILoanCodec} from "@lending-interfaces/ILoanCodec.sol";
import {ICollateralVault} from "@lending-interfaces/ICollateralVault.sol";
import {IAnzaToken} from "@token-interfaces/IAnzaToken.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract TreasureyAccessController is
    ITreasureyAccessController,
    AccessControl
{
    IDebtBook internal _loanContract;
    IDebtTerms internal _loanDebtTerms;
    ILoanManager internal _loanManager;
    ILoanCodec internal _loanCodec;
    ICollateralVault internal _collateralVault;
    IAnzaToken internal _anzaToken;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_LOAN_CONTRACT_, _ADMIN_);
        _setRoleAdmin(_DEBT_MARKET_, _ADMIN_);

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

        _loanContract = IDebtBook(_loanContractAddress);
        _loanDebtTerms = IDebtTerms(_loanContractAddress);
        _loanCodec = ILoanCodec(_loanContractAddress);
        _loanManager = ILoanManager(_loanContractAddress);
    }
}
