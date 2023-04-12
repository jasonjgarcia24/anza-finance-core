// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../contracts/domain/LoanContractRoles.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import {LibLoanContractIndexer as Indexer} from "../../contracts/libraries/LibLoanContract.sol";
import {Test, LoanContractDeployer, LoanContractSubmitted} from "../LoanContract.t.sol";

contract LoanContractTestDeployment is LoanContractDeployer {
    function testDeploymentStateVars() public {
        assertEq(loanContract.collateralVault(), address(loanCollateralVault));
        assertEq(loanContract.totalDebts(), 0);
    }
}

contract LoanContractTestAccessControl is LoanContractDeployer {
    function testHasRole() public {
        assertTrue(loanContract.hasRole(ADMIN, admin));
        assertTrue(loanContract.hasRole(TREASURER, address(loanTreasurer)));
        assertTrue(loanContract.hasRole(COLLECTOR, collector));
    }

    function testDoesNotHaveRole() public {
        assertFalse(loanContract.hasRole(ADMIN, treasurer));
        assertFalse(loanContract.hasRole(ADMIN, collector));

        assertFalse(loanContract.hasRole(TREASURER, admin));
        assertFalse(loanContract.hasRole(TREASURER, collector));

        assertFalse(loanContract.hasRole(COLLECTOR, admin));
        assertFalse(loanContract.hasRole(COLLECTOR, treasurer));
    }

    function testGrantRole() public {
        vm.startPrank(admin);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(ADMIN, alt_account, admin);
        loanContract.grantRole(ADMIN, alt_account);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(TREASURER, alt_account, admin);
        loanContract.grantRole(TREASURER, alt_account);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(COLLECTOR, alt_account, admin);
        loanContract.grantRole(COLLECTOR, alt_account);

        vm.stopPrank();
    }

    function testCannotGrantRole() public {
        // Fail call from treasurer
        vm.startPrank(treasurer);
        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, treasurer));
        loanContract.grantRole(ADMIN, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, treasurer));
        loanContract.grantRole(TREASURER, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, treasurer));
        loanContract.grantRole(COLLECTOR, alt_account);
        vm.stopPrank();

        // Fail call from collector
        vm.startPrank(collector);
        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, collector));
        loanContract.grantRole(ADMIN, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, collector));
        loanContract.grantRole(TREASURER, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, collector));
        loanContract.grantRole(COLLECTOR, alt_account);
        vm.stopPrank();

        // Fail call from alt_account
        vm.startPrank(alt_account);
        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, alt_account));
        loanContract.grantRole(ADMIN, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, alt_account));
        loanContract.grantRole(TREASURER, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(ADMIN, alt_account));
        loanContract.grantRole(COLLECTOR, alt_account);
        vm.stopPrank();
    }

    function __getCheckRoleFailMsg(
        bytes32 _role,
        address _account
    ) private pure returns (bytes memory) {
        return
            bytes(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
    }
}

contract LoanContractTestERC1155URIStorage is LoanContractSubmitted {
    function testUriStateVars() public {
        // URI for collateralized token should be the collateralized
        // token's URI.
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);

        assertEq(
            anzaToken.uri(_borrowerTokenId),
            demoToken.tokenURI(collateralId)
        );

        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));
    }
}
