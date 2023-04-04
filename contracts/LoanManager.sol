// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/ILoanContract.sol";
import "./token/interfaces/IAnzaToken.sol";

contract LoanManager {
    ILoanContract private __loanContract;
    IAnzaToken private __anzaToken;

    constructor(address _loanContract, address _anzaToken) {
        __loanContract = ILoanContract(_loanContract);
        __anzaToken = IAnzaToken(_anzaToken);
    }
}
