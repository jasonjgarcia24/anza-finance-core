// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import "@custom-errors/StdLoanErrors.sol";
import "@custom-errors/StdTreasureyErrors.sol";
import "@custom-errors/StdManagerErrors.sol";
import "@custom-errors/StdNotaryErrors.sol";
import "@custom-errors/StdCodecErrors.sol";

import {ILoanNotary, IDebtNotary, ISponsorshipNotary, IRefinanceNotary} from "@lending-interfaces/ILoanNotary.sol";
import {LibLoanContractStates as States} from "@helper-libraries/LibLoanContractConstants.sol";

import {Setup, AnzaDebtStorefront} from "@test-base/Setup__test.sol";
import {LoanContractSubmitted} from "@test-contract/LoanContract__test.sol";
import {IAnzaDebtStorefrontEvents} from "@test-storefront-interfaces/IAnzaDebtStorefrontEvents__test.sol";

abstract contract AnzaDebtStorefrontUnitTest is
    IAnzaDebtStorefrontEvents,
    LoanContractSubmitted
{
    function setUp() public virtual override {
        super.setUp();
    }

    function _testAnzaDebtStorefront__FuzzFailBuyDebt(
        IDebtNotary.DebtParams memory _debtParams,
        bytes memory _signature,
        bytes4 _expectedError
    ) internal {
        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            _debtParams,
            _signature,
            0,
            _expectedError
        );
    }

    function _testAnzaDebtStorefront__FuzzFailBuyDebt(
        IDebtNotary.DebtParams memory _debtParams,
        bytes memory _signature,
        uint256 _timeWarp,
        bytes4 _expectedError
    ) internal {
        uint256 _debtId = loanContract.totalDebts();

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
            loanContract.debtBalance(_debtId),
            _PRINCIPAL_,
            "2 :: Debt balance should be _PRINCIPAL_"
        );

        if (_timeWarp != 0) vm.warp(_timeWarp);

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        (bool _success, bytes memory _data) = address(anzaDebtMarket).call{
            value: _debtParams.price
        }(
            abi.encodePacked(
                address(anzaDebtStorefront),
                abi.encodeWithSignature(
                    "buyDebt(address,uint256,uint256,bytes)",
                    _debtParams.collateralAddress,
                    _debtParams.collateralId,
                    _debtParams.termsExpiry,
                    _signature
                )
            )
        );
        vm.stopPrank();

        assertTrue(_success == false, "3 :: buyDebt test should fail.");

        assertEq(
            bytes4(_data),
            _expectedError,
            "4 :: buyDebt test error type incorrect"
        );

        _borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
        assertEq(
            anzaToken.borrowerOf(_debtId),
            borrower,
            "5 :: borrower should be unchanged"
        );
        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            borrower,
            "6 :: AnzaToken owner should be unchanged"
        );
        assertEq(
            loanContract.debtBalance(_debtId),
            _PRINCIPAL_,
            "7 :: Debt balance should be unchanged"
        );
    }
}

contract AnzaDebtStorefrontTest is AnzaDebtStorefrontUnitTest {
    function testAnzaDebtStorefront__StorefrontStateVars() public {
        assertEq(anzaDebtStorefront.loanContract(), address(loanContract));
        assertEq(
            anzaDebtStorefront.loanTreasurerAddress(),
            address(loanTreasurer)
        );
        assertEq(anzaDebtStorefront.anzaToken(), address(anzaToken));
    }
}

contract AnzaDebtStorefront__BasicBuyDebtTest is AnzaDebtStorefrontUnitTest {
    function testAnzaDebtStorefront__BasicBuyDebt() public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtId = loanContract.totalDebts();
        uint256 _debtListingNonce = anzaDebtMarket.nonce();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            })
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
            loanContract.debtBalance(_debtId),
            _PRINCIPAL_,
            "2 :: Debt balance should be _PRINCIPAL_"
        );

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        (bool _success, ) = address(anzaDebtMarket).call{value: _price}(
            abi.encodePacked(
                address(anzaDebtStorefront),
                abi.encodeWithSignature(
                    "buyDebt(address,uint256,uint256,bytes)",
                    address(demoToken),
                    collateralId,
                    _termsExpiry,
                    _signature
                )
            )
        );
        assertTrue(_success, "3 :: buyDebt test should succeed.");

        vm.stopPrank();

        assertTrue(
            anzaToken.borrowerOf(_debtId) != borrower,
            "4 :: borrower account should not be borrower"
        );
        assertEq(
            anzaToken.borrowerOf(_debtId),
            alt_account,
            "5 :: alt_account account should be alt_account"
        );
        assertEq(
            anzaToken.ownerOf(_borrowerTokenId),
            alt_account,
            "6 :: AnzaToken owner should be alt_account"
        );
        assertEq(
            anzaToken.lenderOf(_debtId),
            lender,
            "7 :: lender account should still be lender"
        );
        assertEq(
            loanContract.debtBalance(_debtId),
            _PRINCIPAL_ - _price,
            "8 :: Debt balance should be _PRINCIPAL_ - _price"
        );
    }

    function testAnzaDebtStorefront__BasicBuySponsorship() public {
        uint256 _debtId = loanContract.totalDebts();
        uint256 _sponsorshipListingNonce = anzaDebtMarket.nonce();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);
        uint256 _balance = loanContract.debtBalance(_debtId);
        uint256 _price = _balance - 1;

        bytes memory _signature = createListingSignature(
            lenderPrivKey,
            ISponsorshipNotary.SponsorshipParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _sponsorshipListingNonce,
                termsExpiry: _termsExpiry
            })
        );

        uint256 _lenderTokenId = anzaToken.lenderTokenId(_debtId);
        assertEq(
            anzaToken.lenderOf(_debtId),
            lender,
            "0 :: lender should be lender"
        );
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "1 :: AnzaToken owner should be lender"
        );
        assertEq(
            loanContract.debtBalance(_debtId),
            _balance,
            "2 :: Debt balance should be _balance"
        );

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        (bool _success, ) = address(anzaDebtMarket).call{value: _price}(
            abi.encodePacked(
                address(anzaSponsorshipStorefront),
                abi.encodeWithSignature(
                    "buySponsorship(uint256,uint256,bytes)",
                    _debtId,
                    _termsExpiry,
                    _signature
                )
            )
        );
        assertTrue(_success, "3 :: buySponsorship test should succeed.");
        vm.stopPrank();

        uint256 _newDebtId = loanContract.totalDebts();
        uint256 _newLenderTokenId = anzaToken.lenderTokenId(_newDebtId);

        assertEq(
            anzaToken.lenderOf(_debtId),
            lender,
            "4 :: lender account should be lender for original debt ID"
        );
        assertEq(
            anzaToken.lenderOf(_newDebtId),
            alt_account,
            "5 :: alt_account account should be alt_account for new debt ID"
        );
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "6 :: AnzaToken owner should be lender for original lender token ID"
        );
        assertEq(
            anzaToken.ownerOf(_newLenderTokenId),
            alt_account,
            "7 :: AnzaToken owner should be alt_account for new lender token ID"
        );
        assertEq(
            anzaToken.borrowerOf(_debtId),
            borrower,
            "8 :: borrower account should be borrower for original debt ID"
        );
        assertEq(
            anzaToken.borrowerOf(_newDebtId),
            borrower,
            "9 :: borrower account should be borrower for new debt ID"
        );
        assertEq(
            loanContract.debtBalance(_debtId),
            1,
            "10 :: Debt balance should be 1 for original debt ID"
        );
        assertEq(
            loanContract.debtBalance(_newDebtId),
            _price >= _balance ? _balance : _price,
            "11 :: Debt balance should be min(_price, _balance) for new debt ID"
        );
    }

    function testAnzaDebtStorefront__BasicBuyRefinance() public {
        uint256 _debtId = loanContract.totalDebts();
        uint256 _sponsorshipListingNonce = anzaDebtMarket.nonce();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);
        uint256 _balance = loanContract.debtBalance(_debtId);
        uint256 _price = _balance - 1;

        bytes32 _contractTerms = createContractTerms(
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IRefinanceNotary.RefinanceParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _sponsorshipListingNonce,
                termsExpiry: _termsExpiry,
                contractTerms: _contractTerms
            })
        );

        uint256 _lenderTokenId = anzaToken.lenderTokenId(_debtId);
        assertEq(
            anzaToken.lenderOf(_debtId),
            lender,
            "0 :: lender should be lender"
        );
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "1 :: AnzaToken owner should be lender"
        );
        assertEq(
            loanContract.debtBalance(_debtId),
            _balance,
            "2 :: Debt balance should be _balance"
        );

        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        (bool _success, ) = address(anzaDebtMarket).call{value: _price}(
            abi.encodePacked(
                address(anzaRefinanceStorefront),
                abi.encodeWithSignature(
                    "buyRefinance(uint256,uint256,bytes32,bytes)",
                    _debtId,
                    _termsExpiry,
                    _contractTerms,
                    _signature
                )
            )
        );
        assertTrue(_success, "3 :: buyRefinance test should succeed.");
        vm.stopPrank();

        uint256 _newDebtId = loanContract.totalDebts();
        uint256 _newLenderTokenId = anzaToken.lenderTokenId(_newDebtId);

        assertEq(
            anzaToken.lenderOf(_debtId),
            lender,
            "4 :: lender account should be lender for original debt ID"
        );
        assertEq(
            anzaToken.lenderOf(_newDebtId),
            alt_account,
            "5 :: alt_account account should be alt_account for new debt ID"
        );
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "6 :: AnzaToken owner should be lender for original lender token ID"
        );
        assertEq(
            anzaToken.ownerOf(_newLenderTokenId),
            alt_account,
            "7 :: AnzaToken owner should be alt_account for new lender token ID"
        );
        assertEq(
            anzaToken.borrowerOf(_debtId),
            borrower,
            "8 :: borrower account should be borrower for original debt ID"
        );
        assertEq(
            anzaToken.borrowerOf(_newDebtId),
            borrower,
            "9 :: borrower account should be borrower for new debt ID"
        );
        assertEq(
            loanContract.debtBalance(_debtId),
            1,
            "10 :: Debt balance should be 1 for original debt ID"
        );
        assertEq(
            loanContract.debtBalance(_newDebtId),
            _price,
            "11 :: Debt balance should be _price for new debt ID"
        );
    }
}

contract AnzaDebtStorefront__FuzzFailBuyDebt is AnzaDebtStorefrontUnitTest {
    function testAnzaDebtStorefront__FuzzFailPriceBuyDebt(
        uint256 _price
    ) public {
        uint256 _debtListingNonce = anzaDebtMarket.nonce();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        vm.assume(_price != _PRINCIPAL_ - 1);

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            })
        );

        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            IDebtNotary.DebtParams({
                price: _PRINCIPAL_ - 1,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            }),
            _signature,
            _INVALID_SIGNER_SELECTOR_
        );
    }

    function testAnzaDebtStorefront__FuzzFailCollateralAddressBuyDebt(
        address _collateralAddress
    ) public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtListingNonce = anzaDebtMarket.nonce();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        vm.assume(_collateralAddress != address(demoToken));

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            })
        );

        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: _collateralAddress,
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            }),
            _signature,
            _INVALID_COLLATERAL_SELECTOR_
        );
    }

    function testAnzaDebtStorefront__FuzzFailCollateralIdBuyDebt(
        uint256 _collateralId
    ) public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtListingNonce = anzaDebtMarket.nonce();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        vm.assume(_collateralId != collateralId);

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            })
        );

        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: _collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            }),
            _signature,
            _INVALID_COLLATERAL_SELECTOR_
        );
    }

    function testAnzaDebtStorefront__FuzzFailNonceBuyDebt(
        uint256 _debtListingNonce
    ) public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        vm.assume(_debtListingNonce != anzaDebtMarket.nonce());

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            })
        );

        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: anzaDebtMarket.nonce(),
                termsExpiry: _termsExpiry
            }),
            _signature,
            _INVALID_SIGNER_SELECTOR_
        );
    }

    function testAnzaDebtStorefront__FuzzFailTermsExpiryBuyDebt(
        uint256 _termsExpiry
    ) public {
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtListingNonce = anzaDebtMarket.nonce();

        vm.assume(_termsExpiry > uint256(_TERMS_EXPIRY_));

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            })
        );

        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: uint256(_TERMS_EXPIRY_)
            }),
            _signature,
            _INVALID_SIGNER_SELECTOR_
        );
    }

    function testAnzaDebtStorefront__FuzzFailAllBuyDebt(
        IDebtNotary.DebtParams memory _debtParams
    ) public {
        vm.assume(_debtParams.price != _PRINCIPAL_ - 1);
        vm.assume(_debtParams.collateralAddress != address(demoToken));
        vm.assume(_debtParams.collateralId != collateralId);
        vm.assume(_debtParams.listingNonce != anzaDebtMarket.nonce());
        vm.assume(_debtParams.termsExpiry > uint256(_TERMS_EXPIRY_));

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            _debtParams
        );

        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            IDebtNotary.DebtParams({
                price: _PRINCIPAL_ - 1,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: anzaDebtMarket.nonce(),
                termsExpiry: uint256(_TERMS_EXPIRY_)
            }),
            _signature,
            _INVALID_SIGNER_SELECTOR_
        );
    }

    function testAnzaDebtStorefront__FuzzFailLoanStateDebt(
        uint256 _timeWarp
    ) public {
        uint256 _debtId = loanContract.totalDebts();
        uint256 _price = _PRINCIPAL_ - 1;
        uint256 _debtListingNonce = anzaDebtMarket.nonce();
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);

        vm.assume(_timeWarp >= loanContract.loanClose(_debtId));

        bytes memory _signature = createListingSignature(
            borrowerPrivKey,
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            })
        );

        _testAnzaDebtStorefront__FuzzFailBuyDebt(
            IDebtNotary.DebtParams({
                price: _price,
                collateralAddress: address(demoToken),
                collateralId: collateralId,
                listingNonce: _debtListingNonce,
                termsExpiry: _termsExpiry
            }),
            _signature,
            _timeWarp,
            _EXPIRED_LOAN_SELECTOR_
        );
    }
}
