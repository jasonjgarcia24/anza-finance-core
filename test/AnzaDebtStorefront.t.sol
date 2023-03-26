// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {AnzaDebtStorefront} from "../contracts/AnzaDebtStorefront.sol";
import {console, stdError, LoanContractSubmitted} from "./LoanContract.t.sol";
import {IAnzaDebtStorefrontEvents} from "./interfaces/IAnzaDebtStorefrontEvents.t.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";

contract AnzaDebtStorefrontUnitTest is
    IAnzaDebtStorefrontEvents,
    LoanContractSubmitted
{
    AnzaDebtStorefront public anzaDebtStorefront;

    function setUp() public virtual override {
        super.setUp();
        anzaDebtStorefront = new AnzaDebtStorefront(
            address(loanContract),
            address(loanTreasurer),
            address(loanCollateralVault),
            address(anzaToken)
        );

        vm.startPrank(admin);
        loanTreasurer.grantRole(
            Roles._DEBT_STOREFRONT_,
            address(anzaDebtStorefront)
        );
        vm.stopPrank();
    }

    function testStorefrontStateVars() public {
        assertEq(anzaDebtStorefront.loanContract(), address(loanContract));
        assertEq(
            anzaDebtStorefront.loanCollateralVault(),
            address(loanCollateralVault)
        );
        assertEq(anzaDebtStorefront.anzaToken(), address(anzaToken));
    }

    function testListDebt() public {
        // uint256 _debtId = loanContract.totalDebts() - 1;
        // uint256 _price = 3;
        // vm.startPrank(borrower);
        // vm.expectEmit(true, true, true, true);
        // emit DebtListed(borrower, _debtId, _price);
        // anzaDebtStorefront.listDebt(_debtId, _price);
        // vm.stopPrank();
    }
}
