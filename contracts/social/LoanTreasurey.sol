// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAnzaDebtToken.sol";
import "./interfaces/ILoanTreasurey.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
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


contract LoanTreasurey is Ownable, ILoanTreasurey, ERC165 {
    address private debtTokenAddress;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ILoanTreasurey).interfaceId || super.supportsInterface(interfaceId);
    }

    function setDebtTokenAddress(address _debtTokenAddress) external onlyOwner() {
        debtTokenAddress = _debtTokenAddress;
    }

    function getDebtTokenAddress() external view returns (address) {
        return debtTokenAddress;
    }
    
    function issueDebtToken(string memory _debtURI) external {
        require(debtTokenAddress != address(0), "Debt token not set");

        ILoanContract _loanContract = ILoanContract(_msgSender());
        IAnzaDebtToken _anzaDebtToken = IAnzaDebtToken(debtTokenAddress);
        
        (, scUint.Property memory _principal,,,,,,) = _loanContract.loanProperties();
        (, uint256 _debtId,) = _loanContract.loanGlobals();

        _anzaDebtToken.mintDebt(_msgSender(), _debtId, _principal._value, _debtURI);
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