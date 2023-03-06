// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import {IERC721Events} from "./interfaces/IERC721Events.t.sol";
import {ILoanContractEvents} from "./interfaces/ILoanContractEvents.t.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LoanContractDeployer, LoanSigned, LoanContractMinter} from "./LoanContract.t.sol";
import {LoanContractERC1155URIStorage} from "./LoanContractDeployment.t.sol";
import {DemoToken} from "../contracts/DemoToken.sol";
import {LibLoanContractStates as States} from "../contracts/utils/LibLoanContractStates.sol";
import {LibLoanContractMetadata as Metadata} from "../contracts/libraries/LibLoanContract.sol";

contract LoanContractTestSubmit is
    LoanSigned,
    ILoanContractEvents,
    IERC721Events
{
    uint256 thing = 0x10;

    function setUp() public virtual override {
        super.setUp();
    }

    function testLenderSubmitProposal() public {
        console.log("!!!!!!!!!!!!!!!!!");

        // uint256 debtId = loanContract.totalDebts();
        // assertEq(debtId, 0);

        // // Lender ALC debt tokens minting
        // vm.expectEmit(true, true, true, true);
        // emit TransferSingle(lender, address(0), lender, debtId, principal);

        // // Borrower NFT minting
        // vm.expectEmit(true, true, true, true);
        // emit TransferSingle(
        //     lender,
        //     address(0),
        //     borrower,
        //     debtId + 1,
        //     principal
        // );

        // // Loan proposal submitted
        // vm.expectEmit(true, true, true, true);
        // emit LoanContractInitialized(address(demoToken), collateralId, debtId);

        // Submit proposal
        vm.deal(lender, 100 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: principal}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,uint256,bytes)",
                contractTerms,
                address(demoToken),
                collateralId,
                collateralNonce,
                signature
            )
        );
        require(success);
        vm.stopPrank();

        // // Verify loanState for this debt ID
        // assertTrue(
        //     loanContract.loanStates(debtId) == States.LoanState.ACTIVE_COMMITTED
        // );

        // // Verify tokenData for this debt ID
        // (
        //     address actualCollateralAddress,
        //     uint256 actualCollateralId,
        //     uint256 actualPrincipal,
        //     uint256 actualFixedInterstRate,
        //     uint256 actualDuration,
        //     uint256 actualUnpaidBalance,
        //     uint256 actualWithdrawableBalance
        // ) = loanContract.tokens(debtId);

        // assertEq(actualCollateralAddress, address(demoToken));
        // assertEq(actualCollateralId, collateralId);
        // assertEq(actualPrincipal, principal);
        // assertEq(actualFixedInterstRate, fixedInterestRate);
        // assertEq(actualDuration, duration);
        // assertEq(actualUnpaidBalance, principal);
        // assertEq(actualWithdrawableBalance, 0);

        // // Verify debtIds for this collateral
        // assertEq(loanContract.debtIds(address(demoToken), collateralId, 0), 0);

        // // Verify no additional debtIds set for this collateral
        // vm.expectRevert(bytes(""));
        // loanContract.debtIds(address(demoToken), collateralId, 1);

        // // Verify total supply of a token ID
        // assertEq(loanContract.totalDebtSupply(debtId), principal);
        // assertEq(loanContract.totalDebtSupply(debtId + 1), principal);

        // // Verify loan participants
        // assertEq(loanContract.borrowerOf(debtId), borrower);
        // assertEq(loanContract.lenderOf(debtId), lender);

        // // Verify token balances
        // address[] memory accounts = new address[](2);
        // accounts[0] = lender;
        // accounts[1] = borrower;

        // uint256[] memory ids = new uint256[](2);
        // ids[0] = debtId;
        // ids[1] = debtId + 1;

        // uint256[] memory balances = new uint256[](2);
        // balances[0] = principal;
        // balances[1] = principal;

        // assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // // Verify debt exists
        // assertTrue(loanContract.debtExists(debtId));

        // // Verify debtId is updated at end
        // debtId = loanContract.totalDebts();
        // assertEq(debtId, 1);
    }
}

contract LoanContractSubmit is LoanContractMinter {
    function setUp() public override(LoanContractMinter) {
        super.setUp();
    }

    function testSubmit() public {}

    function testURIStorage() public {
        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(1), _getTokenURI(1));
    }

    function testBalances() public {
        // assertEq(loanContract.balanceOf(borrower, 1));
    }

    function _getTokenURI(uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        return string(abi.encodePacked(nftsURI, Strings.toString(_tokenId)));
    }
}
