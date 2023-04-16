// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../contracts/domain/LoanContractRoles.sol";

import {ICollateralVault} from "../contracts/interfaces/ICollateralVault.sol";
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
     * @note CollateralVault should be the current owner
     * of the collateralized token.
     */
    function testCollateral() public {
        assertEq(
            IERC721(demoToken).ownerOf(collateralId),
            address(collateralVault)
        );
    }

    /*
     * @note CollateralVault should have the following roles assigned
     * to the following accounts:
     *  - _ADMIN_: admin
     *  - _TREASURER_: loanTreasurer
     *  - _LOAN_CONTRACT_: loanContract
     */
    function testHasRole() public {
        assertTrue(collateralVault.hasRole(_ADMIN_, admin));
        assertTrue(
            collateralVault.hasRole(_TREASURER_, address(loanTreasurer))
        );
        assertTrue(
            collateralVault.hasRole(_LOAN_CONTRACT_, address(loanContract))
        );
    }

    /*
     * @note The CollateralVault::getCollateral() should return
     * a ICollateralVault.Collateral struct with the collateralized
     * token's address and ID.
     */
    function testGetCollateralAt() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        ICollateralVault.Collateral memory _collateral = collateralVault
            .getCollateral(_debtId);

        assertEq(_collateral.collateralAddress, address(demoToken));
        assertEq(_collateral.collateralId, collateralId);
    }

    /*
     * @note CollateralVault::withdraw() should only be callable
     * from the LoanTreasurey contract.
     */
    function testWithdraw() public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        // DENY :: Try admin
        vm.startPrank(admin);
        vm.expectRevert(bytes(getAccessControlFailMsg(_TREASURER_, admin)));
        collateralVault.withdraw(admin, _debtId);
        vm.stopPrank();

        // DENY :: Try loan contract
        vm.startPrank(address(loanContract));
        vm.expectRevert(
            bytes(getAccessControlFailMsg(_TREASURER_, address(loanContract)))
        );
        collateralVault.withdraw(address(loanContract), _debtId);
        vm.stopPrank();

        // DENY :: Try loan collateral vault
        vm.startPrank(address(collateralVault));
        vm.expectRevert(
            bytes(
                getAccessControlFailMsg(_TREASURER_, address(collateralVault))
            )
        );
        collateralVault.withdraw(address(collateralVault), _debtId);
        vm.stopPrank();

        // SUCCEED :: Try loan treasurer
        vm.startPrank(address(loanTreasurer));
        vm.expectEmit(true, true, true, true);
        emit WithdrawnCollateral(borrower, address(demoToken), collateralId);
        collateralVault.withdraw(borrower, _debtId);
        vm.stopPrank();
    }

    function testFuzzWithdrawDenied(address _sender) public {
        uint256 _debtId = loanContract.totalDebts() - 1;

        vm.expectRevert(bytes(getAccessControlFailMsg(_TREASURER_, _sender)));

        vm.startPrank(_sender);
        collateralVault.withdraw(borrower, _debtId);
        vm.stopPrank();
    }

    /*
     * @note CollateralVault::onERC721Received() should only allow
     * ERC721 deposits from the LoanContract.
     */
    function testDeposit() public {
        uint256 _testCollateralId = collateralId + 1;

        // DENY :: Try admin
        vm.startPrank(borrower);
        demoToken.approve(admin, _testCollateralId);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(bytes(getAccessControlFailMsg(_LOAN_CONTRACT_, admin)));
        demoToken.safeTransferFrom(
            borrower,
            address(collateralVault),
            _testCollateralId,
            ""
        );
        vm.stopPrank();

        // DENY :: Try loan collateral vault
        vm.startPrank(borrower);
        demoToken.approve(address(collateralVault), _testCollateralId);
        vm.stopPrank();

        vm.startPrank(address(collateralVault));
        vm.expectRevert(
            bytes(
                getAccessControlFailMsg(
                    _LOAN_CONTRACT_,
                    address(collateralVault)
                )
            )
        );
        demoToken.safeTransferFrom(
            borrower,
            address(collateralVault),
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
                getAccessControlFailMsg(_LOAN_CONTRACT_, address(loanTreasurer))
            )
        );
        demoToken.safeTransferFrom(
            borrower,
            address(collateralVault),
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
            address(collateralVault),
            _testCollateralId,
            ""
        );
        vm.stopPrank();

        assertEq(
            collateralVault.totalCollateral(),
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
        vm.expectRevert(
            bytes(getAccessControlFailMsg(_LOAN_CONTRACT_, _sender))
        );
        demoToken.safeTransferFrom(
            borrower,
            address(collateralVault),
            _testCollateralId,
            abi.encodePacked(address(demoToken))
        );
        vm.stopPrank();
    }
}
