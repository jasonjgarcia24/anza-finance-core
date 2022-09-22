// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AContractGlobals.sol";

abstract contract AContractAffirm is AccessControl, AContractGlobals {
    /**
     * @dev Returns the status of "BORROWER" access control.
     *
     * Requirements: NONE
     */
    function isBorrower() public view returns (bool) {
        return hasRole(_BORROWER_ROLE_, _msgSender());
    }

    /**
     * @dev Returns the status of "LENDER" access control.
     *
     * Requirements: NONE
     */
    function isLender() public view returns (bool) {
        return hasRole(_LENDER_ROLE_, _msgSender());
    }
}