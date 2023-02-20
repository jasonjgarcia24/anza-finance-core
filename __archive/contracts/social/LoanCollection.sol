// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ILoanContract.sol";

contract LoanCollection is Ownable {

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function initCollections(address _loanContractAddress) external onlyOwner() {

    }
}