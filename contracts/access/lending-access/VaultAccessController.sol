// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";

import {IVaultAccessController} from "@lending-access/interfaces/IVaultAccessController.sol";

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

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(IVaultAccessController).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
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
