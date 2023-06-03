// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";

import "../domain/LoanContractRoles.sol";

import "../interfaces/IVaultAccessController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract VaultAccessController is
    IVaultAccessController,
    AccessControl
{
    address internal _loanContract;
    address public immutable anzaToken;

    constructor(address _anzaTokenAddress) {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_LOAN_CONTRACT_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);

        anzaToken = _anzaTokenAddress;
    }

    function loanContract() external view returns (address) {
        return _loanContract;
    }

    function setLoanContract(
        address _loanContractAddress
    ) external onlyRole(_ADMIN_) {
        __setLoanContract(_loanContractAddress);
    }

    function __setLoanContract(address _loanContractAddress) private {
        _revokeRole(_LOAN_CONTRACT_, _loanContract);
        _grantRole(_LOAN_CONTRACT_, _loanContractAddress);

        _loanContract = _loanContractAddress;
    }
}
