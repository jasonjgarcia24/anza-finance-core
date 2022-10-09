// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAnzaDebtToken.sol";
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
    address private debtTokenAddress;

    constructor(address _owner, address _debtTokenAddress) {
        transferOwnership(_owner);
        debtTokenAddress = _debtTokenAddress;
    }

    function issueDebtToken(address _loanContractAddress, string memory _debtURI) external onlyOwner() {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        IAnzaDebtToken _anzaDebtToken = IAnzaDebtToken(debtTokenAddress);
        
        (scAddress.Property memory _lender, scUint.Property memory _principal,,,,,,) = _loanContract.loanProperties();
        (, uint256 _debtId,) = _loanContract.loanGlobals();

        _anzaDebtToken.mintDebt(_lender._value, _debtId, _principal._value, _debtURI);
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