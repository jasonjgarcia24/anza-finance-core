// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ILoanCollateralVault} from "../contracts/interfaces/ILoanCollateralVault.sol";
import {ILoanTreasureyEvents} from "./interfaces/ILoanTreasureyEvents.t.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {console, LoanContractSubmitted} from "./LoanContract.t.sol";

contract LoanCollateralTreasureyUnitTest is
    LoanContractSubmitted,
    ILoanTreasureyEvents
{
    function setUp() public virtual override {
        super.setUp();
    }

    /*
     * @note LoanTreasurey state variables validation upon initial
     * contract deployment.
     */
    function testTreasureyStateVars() public {
        // Addresses
        assertEq(loanTreasurer.loanContract(), address(loanContract));
        assertEq(
            loanTreasurer.loanCollateralVault(),
            address(loanCollateralVault)
        );

        //
        assertEq(loanTreasurer.anzaToken(), address(anzaToken));
        assertEq(loanTreasurer.poolBalance(), 0);
    }
}
