// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../contracts/domain/LoanContractRoles.sol";

import {ILoanCollateralVault} from "../contracts/interfaces/ILoanCollateralVault.sol";
import {ILoanCollateralVaultEvents} from "./interfaces/ILoanCollateralVaultEvents.t.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {console, LoanContractSubmitted} from "./LoanContract.t.sol";

contract LoanCollateralVaultUnitTest is
    LoanContractSubmitted,
    ILoanCollateralVaultEvents
{
    function setUp() public virtual override {
        super.setUp();
    }

    /*
     * @note LoanCollateralVault should be the current owner
     * of the collateralized token.
     */
    function testCollateral() public {
        assertEq(
            IERC721(demoToken).ownerOf(collateralId),
            address(loanCollateralVault)
        );
    }

    /*
     * @note LoanCollateralVault should have the following roles assigned
     * to the following accounts:
     *  - ADMIN: admin
     *  - TREASURER: loanTreasurer
     *  - LOAN_CONTRACT: loanContract
     */
    function testHasRole() public {
        assertTrue(loanCollateralVault.hasRole(ADMIN, admin));
        assertTrue(
            loanCollateralVault.hasRole(TREASURER, address(loanTreasurer))
        );
        assertTrue(
            loanCollateralVault.hasRole(LOAN_CONTRACT, address(loanContract))
        );
    }

    /*
     * @note The LoanCollateralVAult::getCollateral() should return
     * a ILoanCollateralVault.Collateral struct with the collateralized
     * token's address and ID.
     */
    function testGetCollateralAt() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        ILoanCollateralVault.Collateral memory _collateral = loanCollateralVault
            .getCollateral(_debtId);

        assertEq(_collateral.collateralAddress, address(demoToken));
        assertEq(_collateral.collateralId, collateralId);
    }

    /*
     * @note LoanCollateralVault::withdraw() should only be callable
     * from the LoanTreasurey contract.
     */
    function testWithdraw() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        // DENY :: Try admin
        vm.startPrank(admin);
        vm.expectRevert(bytes(getAccessControlFailMsg(TREASURER, admin)));
        loanCollateralVault.withdraw(admin, _debtId);
        vm.stopPrank();

        // DENY :: Try loan contract
        vm.startPrank(address(loanContract));
        vm.expectRevert(
            bytes(getAccessControlFailMsg(TREASURER, address(loanContract)))
        );
        loanCollateralVault.withdraw(address(loanContract), _debtId);
        vm.stopPrank();

        // DENY :: Try loan collateral vault
        vm.startPrank(address(loanCollateralVault));
        vm.expectRevert(
            bytes(
                getAccessControlFailMsg(TREASURER, address(loanCollateralVault))
            )
        );
        loanCollateralVault.withdraw(address(loanCollateralVault), _debtId);
        vm.stopPrank();

        // SUCCEED :: Try loan treasurer
        vm.startPrank(address(loanTreasurer));
        vm.expectEmit(true, true, true, true);
        emit WithdrawnCollateral(borrower, address(demoToken), collateralId);
        loanCollateralVault.withdraw(borrower, _debtId);
        vm.stopPrank();
    }

    function testFuzzWithdrawDenied(address _sender) public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.expectRevert(bytes(getAccessControlFailMsg(TREASURER, _sender)));

        vm.startPrank(_sender);
        loanCollateralVault.withdraw(borrower, _debtId);
        vm.stopPrank();
    }

    /*
     * @note LoanCollateralVault::onERC721Received() should only allow
     * ERC721 deposits from the LoanContract.
     */
    function testDeposit() public {
        uint256 _testCollateralId = collateralId + 1;

        // DENY :: Try admin
        vm.startPrank(borrower);
        demoToken.approve(admin, _testCollateralId);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(bytes(getAccessControlFailMsg(LOAN_CONTRACT, admin)));
        demoToken.safeTransferFrom(
            borrower,
            address(loanCollateralVault),
            _testCollateralId,
            ""
        );
        vm.stopPrank();

        // DENY :: Try loan collateral vault
        vm.startPrank(borrower);
        demoToken.approve(address(loanCollateralVault), _testCollateralId);
        vm.stopPrank();

        vm.startPrank(address(loanCollateralVault));
        vm.expectRevert(
            bytes(
                getAccessControlFailMsg(
                    LOAN_CONTRACT,
                    address(loanCollateralVault)
                )
            )
        );
        demoToken.safeTransferFrom(
            borrower,
            address(loanCollateralVault),
            _testCollateralId,
            ""
        );
        vm.stopPrank();

        // DENY :: Try loan collateral vault
        vm.startPrank(borrower);
        demoToken.approve(address(loanTreasurer), _testCollateralId);
        vm.stopPrank();

        vm.startPrank(address(loanTreasurer));
        vm.expectRevert(
            bytes(
                getAccessControlFailMsg(LOAN_CONTRACT, address(loanTreasurer))
            )
        );
        demoToken.safeTransferFrom(
            borrower,
            address(loanCollateralVault),
            _testCollateralId,
            ""
        );
        vm.stopPrank();

        // SUCCEED :: Try loan contract
        vm.startPrank(borrower);
        demoToken.approve(address(loanContract), _testCollateralId);
        vm.stopPrank();

        vm.startPrank(address(loanContract));
        vm.expectEmit(true, true, true, true);
        emit DepositedCollateral(
            borrower,
            address(demoToken),
            _testCollateralId
        );
        demoToken.safeTransferFrom(
            borrower,
            address(loanCollateralVault),
            _testCollateralId,
            ""
        );
        vm.stopPrank();

        assertEq(
            loanCollateralVault.totalCollateral(),
            loanContract.totalDebts() + 1
        );
    }

    function testFuzzDepositDenied(address _sender) public {
        uint256 _testCollateralId = collateralId + 1;

        // DENY :: Try admin
        vm.startPrank(borrower);
        demoToken.approve(_sender, _testCollateralId);
        vm.stopPrank();

        vm.startPrank(_sender);
        vm.expectRevert(bytes(getAccessControlFailMsg(LOAN_CONTRACT, _sender)));
        demoToken.safeTransferFrom(
            borrower,
            address(loanCollateralVault),
            _testCollateralId,
            abi.encodePacked(address(demoToken))
        );
        vm.stopPrank();
    }
}
