// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../contracts/domain/LoanContractRoles.sol";
import "../contracts/domain/LoanNotaryErrorCodes.sol";

import {AnzaDebtStorefront} from "../contracts/AnzaDebtStorefront.sol";
import {IDebtNotary} from "../contracts/interfaces/ILoanNotary.sol";
import {console, LoanContractSubmitted} from "./LoanContract.t.sol";
import {IAnzaDebtStorefrontEvents} from "./interfaces/IAnzaDebtStorefrontEvents.t.sol";
import {LibLoanNotary as Signing} from "../contracts/libraries/LibLoanNotary.sol";
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
        loanTreasurer.grantRole(_DEBT_STOREFRONT_, address(anzaDebtStorefront));
        vm.stopPrank();
    }

    function createListingSignature(
        uint256 _price,
        uint256 _debtId
    ) public virtual returns (bytes memory _signature) {
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);
        uint256 _debtListingNonce = loanTreasurer.getDebtSaleNonce(_debtId);

        bytes32 _message = Signing.typeDataHash(
            IDebtNotary.DebtListingParams({
                price: _price,
                debtId: _debtId,
                debtListingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            }),
            Signing.DomainSeparator({
                name: "AnzaDebtStorefront",
                version: "0",
                chainId: block.chainid,
                contractAddress: address(anzaDebtStorefront)
            })
        );

        // Sign borrower's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function createListingSignature(
        uint256 _price,
        uint256 _debtId,
        uint256 _debtListingNonce
    ) public virtual returns (bytes memory _signature) {
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        bytes32 _message = Signing.typeDataHash(
            IDebtNotary.DebtListingParams({
                price: _price,
                debtId: _debtId,
                debtListingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            }),
            Signing.DomainSeparator({
                name: "AnzaDebtStorefront",
                version: "0",
                chainId: block.chainid,
                contractAddress: address(anzaDebtStorefront)
            })
        );

        // Sign borrower's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function testAnzaDebtStorefront__StorefrontStateVars() public {
        assertEq(anzaDebtStorefront.loanContract(), address(loanContract));
        assertEq(anzaDebtStorefront.loanTreasurer(), address(loanTreasurer));
        assertEq(anzaDebtStorefront.anzaToken(), address(anzaToken));
    }

    function testAnzaDebtStorefront__BasicBuyDebt() public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtId = loanContract.totalDebts();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        console.log(
            "loanTreasurer.getDebtSaleNonce(_debtId): %s",
            loanTreasurer.getDebtSaleNonce(_debtId)
        );

        bytes memory _signature = createListingSignature(_price, _debtId);

        uint256 _borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
        assertEq(
            anzaToken.borrowerOf(_debtId),
            borrower,
            "0 :: borrower should be borrower"
        );
        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            borrower,
            "1 :: AnzaToken owner should be borrower"
        );
        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_,
            "2 :: Debt balance should be _PRINCIPAL_"
        );

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        vm.expectEmit(true, true, true, true, address(anzaDebtStorefront));
        emit DebtPurchased(alt_account, _debtId, _price);
        (bool _success, ) = address(anzaDebtStorefront).call{value: _price}(
            abi.encodeWithSignature(
                "buyDebt(uint256,uint256,bytes)",
                _debtId,
                _termsExpiry,
                _signature
            )
        );
        require(_success);
        vm.stopPrank();

        assertTrue(
            anzaToken.borrowerOf(_debtId) != borrower,
            "3 :: borrower account should not be borrower"
        );
        assertEq(
            anzaToken.borrowerOf(_debtId),
            alt_account,
            "4 :: alt_account account should be alt_account"
        );
        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            alt_account,
            "4 :: AnzaToken owner should be alt_account"
        );
        console.log(
            "anzaToken.lenderOf(_debtId): %s",
            anzaToken.lenderOf(_debtId)
        );
        assertEq(
            anzaToken.lenderOf(_debtId),
            lender,
            "5 :: lender account should still be lender"
        );
        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_ - _price,
            "6 :: Debt balance should be _PRINCIPAL_ - _price"
        );
    }

    function testAnzaDebtStorefront__FailBasicBuyDebt(
        uint256 _debtListingNonce
    ) public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtId = loanContract.totalDebts();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);
        bool _isValidDebtListing = _debtListingNonce ==
            loanTreasurer.getDebtSaleNonce(_debtId);

        console.log("debtListingNonce: %s", _debtListingNonce);
        console.log(
            "loanTreasurer.getDebtSaleNonce(_debtId): %s",
            loanTreasurer.getDebtSaleNonce(_debtId)
        );

        bytes memory _signature = createListingSignature(
            _price,
            _debtId,
            _debtListingNonce
        );

        uint256 _borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
        assertEq(
            anzaToken.borrowerOf(_debtId),
            borrower,
            "0 :: borrower should be borrower"
        );
        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            borrower,
            "1 :: AnzaToken owner should be borrower"
        );
        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_,
            "2 :: Debt balance should be _PRINCIPAL_"
        );

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);

        if (_isValidDebtListing) {
            vm.expectEmit(true, true, true, true, address(anzaDebtStorefront));
            emit DebtPurchased(alt_account, _debtId, _price);
        }
        (bool _success, bytes memory _data) = address(anzaDebtStorefront).call{
            value: _price
        }(
            abi.encodeWithSignature(
                "buyDebt(uint256,uint256,bytes)",
                _debtId,
                _termsExpiry,
                _signature
            )
        );
        vm.stopPrank();

        if (!_isValidDebtListing) {
            require(
                bytes4(_data) == _INVALID_PARTICIPANT_SELECTOR_,
                "3 :: buyDebt test failed."
            );
            return;
        }

        require(_success, "3 :: buyDebt test failed.");

        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            borrower,
            "4 :: AnzaToken owner should be borrower"
        );
        assertTrue(
            anzaToken.borrowerOf(_debtId) != borrower,
            "5 :: borrower should not have AnzaToken borrower token role"
        );
        assertEq(
            anzaToken.borrowerOf(_debtId),
            alt_account,
            "6 :: alt_account should have AnzaToken borrower token role"
        );
        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_ - _price,
            "7 :: Debt balance should be _PRINCIPAL_ - _price"
        );
    }

    function testAnzaDebtStorefront__ReplicaBuyDebt() public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtId = loanContract.totalDebts();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        // // Mint replica token
        // vm.deal(borrower, 1 ether);
        // vm.startPrank(borrower);
        // loanContract.mintReplica(_debtId);
        // vm.stopPrank();

        bytes memory _signature = createListingSignature(_price, _debtId);

        uint256 _borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
        assertEq(
            anzaToken.borrowerOf(_debtId),
            borrower,
            "0 :: borrower should have AnzaToken borrower token role"
        );
        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            borrower,
            "1 :: AnzaToken owner should be borrower"
        );
        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_,
            "2 :: Debt balance should be _PRINCIPAL_"
        );

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        vm.expectEmit(true, true, true, true);
        emit DebtPurchased(alt_account, _debtId, _price);
        (bool _success, ) = address(anzaDebtStorefront).call{value: _price}(
            abi.encodeWithSignature(
                "buyDebt(uint256,uint256,bytes)",
                _debtId,
                _termsExpiry,
                _signature
            )
        );
        require(_success);
        vm.stopPrank();

        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            alt_account,
            "3 :: AnzaToken owner should be alt_account"
        );
        assertTrue(
            anzaToken.borrowerOf(_debtId) != borrower,
            "4 :: borrower should not have AnzaToken borrower token role"
        );
        assertEq(
            anzaToken.borrowerOf(_debtId),
            alt_account,
            "5 :: alt_account should have AnzaToken borrower token role"
        );
        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_ - _price,
            "6 :: Debt balance should be _PRINCIPAL_ - _price"
        );
    }
}
