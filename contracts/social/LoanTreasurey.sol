// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States
} from "./libraries/LibContractMaster.sol";

import "./interfaces/ILoanContract.sol";
import "./LoanContract.sol";
import {
    StateControlUint as scUint,
    StateControlAddress as scAddress
} from "../utils/StateControl.sol";


contract LoanTreasurey is Ownable {
    LoanContract internal loanContract;

    constructor() {
        // console.logAddress(owner());
    }

    function checkMaturity(address _loanContractAddress) external {
        loanContract = LoanContract(_loanContractAddress);

        (,,States.LoanState _state) = loanContract.loanGlobals();
        console.log(uint256(_state));
        require(_state > States.LoanState.FUNDED, "Loan contract must be active.");
        
        (,,,,,,scUint.Property memory _balance,) = loanContract.loanProperties();
        
        if (_balance._value != 0) {
            __setDefault(_loanContractAddress);
        }

        (,,States.LoanState _newState) = loanContract.loanGlobals();
        console.log(uint256(_newState));
    }

    function __setDefault(address _loanContract) private {
        ILoanContract(_loanContract).initDefault();
    }
}