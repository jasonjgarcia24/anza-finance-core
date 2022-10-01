// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States
} from "./libraries/LibContractMaster.sol";
import { 
    LibLoanTreasurey as Treasurey,
    TreasurerUtils as Utils
} from "./libraries/LibContractTreasurer.sol";

import "./interfaces/ILoanContract.sol";
import {
    StateControlUint as scUint,
    StateControlAddress as scAddress
} from "../utils/StateControl.sol";


contract LoanTreasurey is Ownable {

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function updateBalance(address _loanContractAddress) external onlyOwner() {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        _loanContract.updateBalance();

        Treasurey.assessMaturity_(_loanContractAddress);
    }

    function assessMaturity(address _loanContractAddress) external onlyOwner() {
        Treasurey.assessMaturity_(_loanContractAddress);

        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        (,,States.LoanState _state) = _loanContract.loanGlobals();

        if (_state >= States.LoanState.PAID) { return; }
        _loanContract.updateBalance();

        if (_state == States.LoanState.DEFAULT) {
            
        }
    }
}