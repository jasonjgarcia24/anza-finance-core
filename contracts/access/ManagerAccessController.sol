// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "../domain/LoanContractRoles.sol";

import "../interfaces/IManagerAccessController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ManagerAccessController is IManagerAccessController, AccessControl {
    address internal _collateralVault;
    address internal _loanTreasurer;

    IAnzaToken internal _anzaToken;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    function loanTreasurer() external view returns (address) {
        return _loanTreasurer;
    }

    function collateralVault() external view returns (address) {
        return _collateralVault;
    }

    function setAnzaToken(
        address _anzaTokenAddress
    ) external onlyRole(_ADMIN_) {
        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    function setLoanTreasurer(
        address _loanTreasurerAddress
    ) external onlyRole(_ADMIN_) {
        __setLoanTreasurer(_loanTreasurerAddress);
    }

    function setCollateralVault(
        address _collateralVaultAddress
    ) external onlyRole(_ADMIN_) {
        _collateralVault = _collateralVaultAddress;
    }

    function _grantRole(
        bytes32 _role,
        address _account
    ) internal virtual override {
        (_role == _TREASURER_)
            ? __setLoanTreasurer(_account)
            : super._grantRole(_role, _account);
    }

    function __setLoanTreasurer(address _loanTreasurerAddress) private {
        _revokeRole(_TREASURER_, _loanTreasurer);
        super._grantRole(_TREASURER_, _loanTreasurerAddress);

        _loanTreasurer = _loanTreasurerAddress;
    }
}
