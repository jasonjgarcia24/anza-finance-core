// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States
} from "./libraries/LibContractMaster.sol";
import { TreasurerUtils as Utils } from "./libraries/LibContractTreasurer.sol";

import "./interfaces/ILoanContract.sol";
import "./LoanContract.sol";
import {
    StateControlUint as scUint,
    StateControlAddress as scAddress
} from "../utils/StateControl.sol";


contract LoanTreasurey is Ownable {
    ILoanContract internal loanContract;

    function assessMaturity(address _loanContractAddress) external {
        loanContract = ILoanContract(_loanContractAddress);

        (,,States.LoanState _originalState) = loanContract.loanGlobals();
        require(_originalState > States.LoanState.FUNDED, "Loan contract must be active.");
        
        (
            ,,,,,,
            scUint.Property memory _balance,
            scUint.Property memory _stopBlockstamp
        ) = loanContract.loanProperties();

        bool _isDefaulted = Utils.isDefaulted_(
            _balance._value, _stopBlockstamp._value, _originalState
        );
        
        if (_isDefaulted) {
            loanContract.initDefault();
            (,,States.LoanState _newState) = loanContract.loanGlobals();
            emit States.LoanStateChanged(_originalState, _newState);
        }
    }
}