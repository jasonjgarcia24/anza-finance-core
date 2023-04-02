// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {AnzaDebtStorefront} from "../contracts/AnzaDebtStorefront.sol";
import {console, stdError, LoanContractSubmitted} from "./LoanContract.t.sol";
import {IAnzaDebtStorefrontEvents} from "./interfaces/IAnzaDebtStorefrontEvents.t.sol";
import {LibLoanContractSigning as Signing, LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractStates as States} from "../contracts/libraries/LibLoanContractConstants.sol";

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
            address(anzaToken)
        );

        vm.startPrank(admin);
        loanTreasurer.grantRole(
            Roles._DEBT_STOREFRONT_,
            address(anzaDebtStorefront)
        );
        vm.stopPrank();
    }

    function createListingSignature(
        bytes32 _listingHash,
        uint256 _price,
        uint256 _debtId
    ) public virtual returns (bytes memory _signature) {
        // Create message for signing
        bytes32 _message = Signing.prefixed(
            keccak256(abi.encode(_listingHash, _price, _debtId))
        );

        // Sign borrower's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function testStorefrontStateVars() public {
        assertEq(anzaDebtStorefront.loanContract(), address(loanContract));
        assertEq(anzaDebtStorefront.loanTreasurer(), address(loanTreasurer));
        assertEq(anzaDebtStorefront.anzaToken(), address(anzaToken));
    }

    function testBuyDebt() public {
        uint256 _debtId = loanContract.totalDebts() - 1;
        uint256 _price = _PRINCIPAL_ - 1;
        bytes32 _listingHash = keccak256(
            "QmWmyoMoctfbAaiEs2G46gpeUmhqFRDW6KWo64y5r581Vz"
        );

        bytes memory _signature = createListingSignature(
            _listingHash,
            _price,
            _debtId
        );

        uint256 _borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
        assertEq(anzaToken.ownerOf(_borrowerTokenId), borrower);
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_);

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        vm.expectEmit(true, true, true, true);
        emit DebtPurchased(alt_account, _debtId, _price);
        (bool _success, ) = address(anzaDebtStorefront).call{value: _price}(
            abi.encodeWithSignature(
                "buyDebt(bytes32,uint256,bytes)",
                _listingHash,
                _debtId,
                _signature
            )
        );
        require(_success);
        vm.stopPrank();

        assertEq(anzaToken.ownerOf(_borrowerTokenId), alt_account);
        assertEq(loanContract.borrower(_debtId), alt_account);
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_ - _price);
    }
}
