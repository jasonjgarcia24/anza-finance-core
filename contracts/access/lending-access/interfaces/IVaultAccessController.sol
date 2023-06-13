// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVaultAccessController {
    function loanContract() external view returns (address);

    function setLoanContract(address _loanContractAddress) external;
}
