// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import {StdVaultErrors} from "@custom-errors/StdVaultErrors.sol";

import {CollateralVault} from "@services/CollateralVault.sol";
import {ICollateralVault} from "@services-interfaces/ICollateralVault.sol";

// import {LoanContractSubmitted} from "@test-contract/LoanContract__test.sol";
import {CollateralVaultEventsSuite} from "@test-utils/events/CollateralVaultEventsSuite__test.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CollateralVaultHarness is CollateralVault {
    struct RecordInput {
        address from;
        address collateralAddress;
        uint256 collateralId;
        uint256 debtId;
        uint256 activeLoanIndex;
    }

    constructor(address _anzaToken) CollateralVault(_anzaToken) {}

    function exposed__record(
        address _from,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) public {
        _record(
            _from,
            _collateralAddress,
            _collateralId,
            _debtId,
            _activeLoanIndex
        );
    }
}

// contract CollateralVaultUnitTest is
//     LoanContratSubmitted,
//     CollateralVaultEventsSuite
// {
//     function setUp() public virtual override {
//         super.setUp();
//     }

//     function testCollateralVault__Pass() public {}

//     /*
//      * @note CollateralVault should be the current owner
//      * of the collateralized token.
//      */
//     function testCollateralVault__Collateral() public {
//         assertEq(
//             IERC721(demoToken).ownerOf(collateralId),
//             address(collateralVault)
//         );
//     }

//     /*
//      * @note CollateralVault should have the following roles assigned
//      * to the following accounts:
//      *  - _ADMIN_: admin
//      *  - _TREASURER_: loanTreasurer
//      *  - _LOAN_CONTRACT_: loanContract
//      */
//     function testCollateralVault__CollateralVaultHasRole() public {
//         assertTrue(
//             collateralVault.hasRole(_ADMIN_, admin),
//             "0 :: admin role not set correctly."
//         );
//         assertTrue(
//             collateralVault.hasRole(_TREASURER_, address(loanTreasurer)),
//             "1 :: treasurer role not set correctly."
//         );
//         assertTrue(
//             collateralVault.hasRole(_LOAN_CONTRACT_, address(loanContract)),
//             "2 :: loan contract role not set correctly."
//         );
//     }

//     // /*
//     //  * @note The CollateralVault::getCollateral() should return
//     //  * a ICollateralVault.Collateral struct with the collateralized
//     //  * token's address and ID.
//     //  */
//     // function testCollateralVault__GetCollateralAt() public {
//     //     // uint256 _debtId = loanContract.totalDebts();
//     //     // ICollateralVault.Collateral memory _collateral = collateralVault
//     //     //     .getCollateral(_debtId);
//     //     // assertEq(
//     //     //     _collateral.collateralAddress,
//     //     //     address(demoToken),
//     //     //     "0 :: collateral address in incorrect."
//     //     // );
//     //     // assertEq(
//     //     //     _collateral.collateralId,
//     //     //     collateralId,
//     //     //     "1 :: collateral id is incorrect."
//     //     // );
//     // }

//     // /*
//     //  * @note CollateralVault::withdraw() should only be callable
//     //  * from the LoanTreasurey contract.
//     //  */
//     // function testCollateralVault__Withdraw() public {
//     //     uint256 _debtId = loanContract.totalDebts();

//     //     // DENY :: Try admin
//     //     vm.startPrank(admin);
//     //     vm.expectRevert(bytes(getAccessControlFailMsg(_TREASURER_, admin)));
//     //     collateralVault.withdraw(admin, _debtId);
//     //     vm.stopPrank();

//     //     // DENY :: Try loan contract
//     //     vm.startPrank(address(loanContract));
//     //     vm.expectRevert(
//     //         bytes(getAccessControlFailMsg(_TREASURER_, address(loanContract)))
//     //     );
//     //     collateralVault.withdraw(address(loanContract), _debtId);
//     //     vm.stopPrank();

//     //     // DENY :: Try loan collateral vault
//     //     vm.startPrank(address(collateralVault));
//     //     vm.expectRevert(
//     //         bytes(
//     //             getAccessControlFailMsg(_TREASURER_, address(collateralVault))
//     //         )
//     //     );
//     //     collateralVault.withdraw(address(collateralVault), _debtId);
//     //     vm.stopPrank();

//     //     // DENY :: Try loan treasurer of unpaid loan
//     //     vm.startPrank(address(loanTreasurer));
//     //     vm.expectRevert(
//     //         abi.encodeWithSelector(StdVaultErrors.UnallowedWithdrawal.selector)
//     //     );
//     //     emit WithdrawnCollateral(borrower, address(demoToken), collateralId);
//     //     collateralVault.withdraw(borrower, _debtId);
//     //     vm.stopPrank();

//     //     // ALLOW :: Try loan treasurer of unpaid loan
//     //     vm.startPrank(borrower);
//     //     vm.deal(borrower, _PRINCIPAL_);
//     //     (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
//     //         abi.encodeWithSignature("depositPayment(uint256)", _debtId)
//     //     );
//     //     require(_success == true, "0 :: deposited payment.");
//     //     vm.stopPrank();

//     //     vm.startPrank(address(loanTreasurer));
//     //     vm.expectEmit(true, true, true, true, address(collateralVault));
//     //     emit WithdrawnCollateral(borrower, address(demoToken), collateralId);
//     //     collateralVault.withdraw(borrower, _debtId);
//     //     vm.stopPrank();
//     // }

//     // function testCollateralVault__FuzzWithdrawDenied(address _sender) public {
//     //     uint256 _debtId = loanContract.totalDebts();

//     //     vm.expectRevert(bytes(getAccessControlFailMsg(_TREASURER_, _sender)));

//     //     vm.startPrank(_sender);
//     //     collateralVault.withdraw(borrower, _debtId);
//     //     vm.stopPrank();
//     // }

//     // /*
//     //  * @note CollateralVault::onERC721Received() should only allow
//     //  * ERC721 deposits from the LoanContract when there is a matching
//     //  * debt ID and the collateral has not previously been stored.
//     //  */
//     // function testCollateralVault__FuzzDirectDepositDenied(
//     //     bytes32 _hashedDebtId
//     // ) public {
//     //     uint256 _testCollateralId = collateralId + 1;

//     //     vm.startPrank(borrower);
//     //     demoToken.approve(admin, _testCollateralId);
//     //     vm.stopPrank();

//     //     vm.startPrank(admin);
//     //     vm.expectRevert(
//     //         abi.encodeWithSelector(StdVaultErrors.UnallowedDeposit.selector)
//     //     );
//     //     demoToken.safeTransferFrom(
//     //         borrower,
//     //         address(collateralVault),
//     //         _testCollateralId,
//     //         abi.encode(_hashedDebtId)
//     //     );
//     //     vm.stopPrank();
//     // }
// }
