// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";

import "../../contracts/domain/LoanContractRoles.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import {LibLoanContractIndexer as Indexer} from "../../contracts/libraries/LibLoanContract.sol";
import {Test, LoanContractDeployer, LoanContractSubmitted} from "../LoanContract.t.sol";

contract LoanContractTestDeployment is LoanContractDeployer {
    function testDeploymentStateVars() public {
        assertEq(loanContract.collateralVault(), address(collateralVault));
        assertEq(loanContract.totalDebts(), 0);
    }
}

contract LoanContractTestAccessControl is LoanContractDeployer {
    function testLoanContractDeployment__HasRole() public {
        assertTrue(loanContract.hasRole(_ADMIN_, admin));
        assertTrue(loanContract.hasRole(_TREASURER_, address(loanTreasurer)));
    }

    function testLoanContractDeployment__DoesNotHaveRole() public {
        assertFalse(loanContract.hasRole(_ADMIN_, treasurer));
        assertFalse(loanContract.hasRole(_ADMIN_, collector));

        assertFalse(loanContract.hasRole(_TREASURER_, admin));
        assertFalse(loanContract.hasRole(_TREASURER_, collector));

        assertFalse(loanContract.hasRole(_COLLECTOR_, admin));
        assertFalse(loanContract.hasRole(_COLLECTOR_, treasurer));
    }

    function testLoanContractDeployment__GrantRole() public {
        vm.startPrank(admin);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(_ADMIN_, alt_account, admin);
        loanContract.grantRole(_ADMIN_, alt_account);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(_TREASURER_, alt_account, admin);
        loanContract.grantRole(_TREASURER_, alt_account);

        vm.stopPrank();
    }

    function testLoanContractDeployment__CannotGrantRole() public {
        // Fail call from treasurer
        vm.startPrank(treasurer);
        vm.expectRevert(__getCheckRoleFailMsg(_ADMIN_, treasurer));
        loanContract.grantRole(_ADMIN_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(_ADMIN_, treasurer));
        loanContract.grantRole(_TREASURER_, alt_account);
        vm.stopPrank();

        // Fail call from collector
        vm.startPrank(collector);
        vm.expectRevert(__getCheckRoleFailMsg(_ADMIN_, collector));
        loanContract.grantRole(_ADMIN_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(_ADMIN_, collector));
        loanContract.grantRole(_TREASURER_, alt_account);
        vm.stopPrank();

        // Fail call from alt_account
        vm.startPrank(alt_account);
        vm.expectRevert(__getCheckRoleFailMsg(_ADMIN_, alt_account));
        loanContract.grantRole(_ADMIN_, alt_account);

        vm.expectRevert(__getCheckRoleFailMsg(_ADMIN_, alt_account));
        loanContract.grantRole(_TREASURER_, alt_account);
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
    function testLoanContractDeployment__UriStateVars() public {
        // URI for collateralized token should be the collateralized
        // token's URI.
        uint256 _debtId = loanContract.totalDebts();
        uint256 _borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);

        assertEq(
            anzaToken.uri(_borrowerTokenId),
            demoToken.tokenURI(collateralId)
        );

        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));
    }
}
