// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LibOfficerRoles as Roles, LibLoanContractIndexer as Indexer} from "../../contracts/libraries/LibLoanContract.sol";
import {Test, LoanContractDeployer, LoanContractSubmitted} from "../LoanContract.t.sol";

contract LoanContractTestDeployment is LoanContractDeployer {
    function testDeploymentStateVars() public {
        assertEq(loanContract.collateralVault(), address(loanCollateralVault));
        assertEq(loanContract.totalDebts(), 0);
    }
}

contract LoanContractTestAccessControl is LoanContractDeployer {
    function testHasRole() public {
        assertTrue(loanContract.hasRole(Roles._ADMIN_, admin));
        assertTrue(loanContract.hasRole(Roles._TREASURER_, treasurer));
        assertTrue(loanContract.hasRole(Roles._COLLECTOR_, collector));
    }

    function testDoesNotHaveRole() public {
        assertFalse(loanContract.hasRole(Roles._ADMIN_, treasurer));
        assertFalse(loanContract.hasRole(Roles._ADMIN_, collector));

        assertFalse(loanContract.hasRole(Roles._TREASURER_, admin));
        assertFalse(loanContract.hasRole(Roles._TREASURER_, collector));

        assertFalse(loanContract.hasRole(Roles._COLLECTOR_, admin));
        assertFalse(loanContract.hasRole(Roles._COLLECTOR_, treasurer));
    }

    function testGrantRole() public {
        vm.startPrank(admin);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(Roles._ADMIN_, alt_account, admin);
        loanContract.grantRole(Roles._ADMIN_, alt_account);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(Roles._TREASURER_, alt_account, admin);
        loanContract.grantRole(Roles._TREASURER_, alt_account);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(Roles._COLLECTOR_, alt_account, admin);
        loanContract.grantRole(Roles._COLLECTOR_, alt_account);

        vm.stopPrank();
    }

    function testCannotGrantRole() public {
        // Fail call from treasurer
        vm.startPrank(treasurer);
        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, treasurer));
        loanContract.grantRole(Roles._ADMIN_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, treasurer));
        loanContract.grantRole(Roles._TREASURER_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, treasurer));
        loanContract.grantRole(Roles._COLLECTOR_, alt_account);
        vm.stopPrank();

        // Fail call from collector
        vm.startPrank(collector);
        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, collector));
        loanContract.grantRole(Roles._ADMIN_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, collector));
        loanContract.grantRole(Roles._TREASURER_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, collector));
        loanContract.grantRole(Roles._COLLECTOR_, alt_account);
        vm.stopPrank();

        // Fail call from alt_account
        vm.startPrank(alt_account);
        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, alt_account));
        loanContract.grantRole(Roles._ADMIN_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, alt_account));
        loanContract.grantRole(Roles._TREASURER_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(Roles._ADMIN_, alt_account));
        loanContract.grantRole(Roles._COLLECTOR_, alt_account);
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
