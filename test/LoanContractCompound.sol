// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ILoanContractEvents} from "./interfaces/ILoanContractEvents.t.sol";
import {Test, console, LoanContractSubmitted} from "./LoanContract.t.sol";

contract LoanContractCompounding is LoanContractSubmitted, ILoanContractEvents {
    function setUp() public virtual override {
        super.setUp();
    }

    function testCompoundingInterest() public {
        
    }
}
