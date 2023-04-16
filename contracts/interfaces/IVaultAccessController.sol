// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILoanCodec.sol";
import "../interfaces/ILoanContract.sol";
import "../interfaces/IAnzaToken.sol";

interface IVaultAccessController {
    function loanContract() external view returns (address);

    function setLoanContract(address _loanContractAddress) external;
}
