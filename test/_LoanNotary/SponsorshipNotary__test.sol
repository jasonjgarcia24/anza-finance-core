// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";
import "@markets-constants/AnzaDebtMarketRoles.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {SponsorshipNotary} from "@services/LoanNotary.sol";
import {ISponsorshipNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";
import {AnzaDebtMarket} from "@markets/AnzaDebtMarket.sol";
import {AnzaSponsorshipStorefront} from "@storefronts/AnzaSponsorshipStorefront.sol";
import {IAnzaBaseMarketParticipant} from "@markets-databases/interfaces/IAnzaBaseMarketParticipant.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

import "@test-databases/TestConstants__test.sol";
import {Setup, Settings} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";

string constant SPONSORSHIP_CONTRACT_NAME = "SponsorshipNotary__test";
string constant SPONSORSHIP_CONTRACT_VERSION = "0";

contract SponsorshipNotaryHarness is SponsorshipNotary {
    constructor(
        address _anzaTokenHarnessAddress
    )
        SponsorshipNotary(
            SPONSORSHIP_CONTRACT_NAME,
            SPONSORSHIP_CONTRACT_VERSION,
            _anzaTokenHarnessAddress
        )
    {}

    function exposed__getSigner(
        SponsorshipParams memory _sponsorshipParams,
        bytes memory _sellerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return _getSigner(_sponsorshipParams, _sellerSignature, ownerOf);
    }

    function exposed__recoverSigner(
        SponsorshipParams memory _sponsorshipParams,
        bytes memory _signature
    ) internal view returns (address) {
        return _recoverSigner(_sponsorshipParams, _signature);
    }
}

abstract contract SponsorshipNotaryInit is Setup {
    SponsorshipNotaryHarness public sponsorshipNotaryHarness;
    SponsorshipNotaryUtils public sponsorshipNotaryUtils;
    AnzaTokenHarness public anzaTokenHarness;
    Notary.DomainSeparator internal _sponsorshipDomainSeparator;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        // Set AnzaTokenHarness
        anzaTokenHarness = new AnzaTokenHarness();

        // Set SponsorshipNotaryHarness
        sponsorshipNotaryHarness = new SponsorshipNotaryHarness(
            address(anzaTokenHarness)
        );

        // Set Anza Debt Marketplace and Storefronts
        anzaDebtMarket = new AnzaDebtMarket();

        anzaSponsorshipStorefront = new AnzaSponsorshipStorefront(
            address(anzaTokenHarness),
            address(loanContract),
            address(loanTreasurer)
        );

        // Set Anza Debt Marketplace access control roles
        anzaDebtMarket.grantRole(
            _SPONSORSHIP_STOREFRONT_,
            address(anzaSponsorshipStorefront)
        );

        sponsorshipDomainSeparator = Notary.DomainSeparator({
            name: "AnzaSponsorshipStorefront",
            version: "0",
            chainId: block.chainid,
            contractAddress: address(anzaSponsorshipStorefront)
        });

        vm.stopPrank();

        _sponsorshipDomainSeparator = Notary.DomainSeparator({
            name: SPONSORSHIP_CONTRACT_NAME,
            version: SPONSORSHIP_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(sponsorshipNotaryHarness)
        });

        // Create SponsorshipNotaryUtils
        sponsorshipNotaryUtils = new SponsorshipNotaryUtils(
            address(anzaTokenHarness),
            address(anzaDebtMarket),
            address(anzaSponsorshipStorefront),
            _sponsorshipDomainSeparator
        );
    }
}

contract SponsorshipNotaryUtils is Settings {
    address private immutable __anzaTokenAddress;
    address private immutable __anzaDebtMarket;
    address private immutable __anzaSponsorshipStorefrontAddress;
    Notary.DomainSeparator private __sponsorshipDomainSeparator;

    constructor(
        address _anzaTokenAddress,
        address _anzaDebtMarket,
        address _anzaSponsorshipStorefrontAddress,
        Notary.DomainSeparator memory _sponsorshipDomainSeparator
    ) {
        __anzaTokenAddress = _anzaTokenAddress;
        __anzaDebtMarket = _anzaDebtMarket;
        __anzaSponsorshipStorefrontAddress = _anzaSponsorshipStorefrontAddress;
        __sponsorshipDomainSeparator = _sponsorshipDomainSeparator;
    }

    function createSponsorshipSignature(
        uint256 _sellerPrivKey,
        ISponsorshipNotary.SponsorshipParams memory _debtSponsorshipParams
    ) public virtual returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            __anzaTokenAddress,
            _debtSponsorshipParams,
            __sponsorshipDomainSeparator
        );

        // Sign seller's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_sellerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function sponsorshipDebt(
        uint256 _debtId,
        uint256 _sellerPrivKey
    ) public virtual returns (bool _success, bytes memory _data) {
        return
            sponsorshipDebt(
                _debtId,
                _sellerPrivKey,
                ContractTerms({
                    firInterval: _FIR_INTERVAL_,
                    fixedInterestRate: _FIXED_INTEREST_RATE_,
                    isFixed: _IS_FIXED_,
                    commitalRatio: _COMMITAL_RATIO_,
                    commitalPeriod: 0,
                    principal: _PRINCIPAL_,
                    gracePeriod: _GRACE_PERIOD_,
                    duration: _DURATION_,
                    termsExpiry: _TERMS_EXPIRY_,
                    lenderRoyalties: _LENDER_ROYALTIES_
                })
            );
    }

    function sponsorshipDebt(
        uint256 _debtId,
        uint256 _sellerPrivKey,
        ContractTerms memory _contractTerms
    ) public virtual returns (bool _success, bytes memory _data) {
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);
        uint256 _listingNonce = IAnzaBaseMarketParticipant(
            __anzaSponsorshipStorefrontAddress
        ).nonce();

        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            });

        // Create seller's signature.
        bytes memory _signature = createSponsorshipSignature(
            _sellerPrivKey,
            _sponsorshipParams
        );

        // Create sponsorship contract.
        return
            initSponsorshipContract(
                _contractTerms.principal,
                _debtId,
                _termsExpiry,
                _packedContractTerms,
                _signature
            );
    }

    function initSponsorshipContract(
        uint256 _price,
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes32 _packedContractTerms,
        bytes memory _signature
    ) public returns (bool _success, bytes memory _data) {
        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        (_success, _data) = address(anzaDebtMarket).call{value: _price}(
            abi.encodePacked(
                __anzaSponsorshipStorefrontAddress,
                abi.encodeWithSignature(
                    "buySponsorship(uint256,uint256,bytes32,bytes)",
                    _debtId,
                    _termsExpiry,
                    _packedContractTerms,
                    _signature
                )
            )
        );
        assertTrue(
            _success,
            "0 :: initSponsorshipContract :: buySponsorship test should succeed."
        );
        vm.stopPrank();
    }
}

abstract contract SponsorshipNotaryGetSignerUnitTest is SponsorshipNotaryInit {
    using AnzaTokenIndexer for uint256;

    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- SponsorshipNotary._getSigner() ---------- */
    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the sponsorship
     * notary's get signer function. This test is intended to pass signature
     * validation.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _debtId The debt id to sponsorship.
     * @param _price The price of the sponsorship listing.
     * @param _listingNonce The nonce of the sponsorship listing.
     * @param _termsExpiry The expiry of the sponsorship listing.
     *
     * @dev Full pass if the function returns the correct seller.
     */
    function testSponsorshipNotary__GetSigner_Fuzz_Pass(
        uint256 _sellerPrivKey,
        uint256 _debtId,
        uint256 _price,
        uint256 _listingNonce,
        uint256 _termsExpiry
    ) public {
        vm.assume(
            _sellerPrivKey != 0 && _sellerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        // Mint debt
        address _seller = vm.addr(_sellerPrivKey);
        uint256 _sellerTokenId = _debtId.debtIdToBorrowerTokenId();
        anzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            });

        // Sign contract.
        bytes memory _sellerSignature = sponsorshipNotaryUtils
            .createSponsorshipSignature(_sellerPrivKey, _sponsorshipParams);

        // Verify and get seller.
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        assertEq(_seller, vm.addr(_sellerPrivKey), "0 :: seller mismatch");
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the sponsorship
     * notary's get signer function. This test is intended to fail signature
     * validation due to the caller of the _getSigner() function being the seller.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _debtId The debt id to sponsorship.
     * @param _price The price of the sponsorship listing.
     * @param _listingNonce The nonce of the sponsorship listing.
     * @param _termsExpiry The expiry of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testSponsorshipNotary__GetSigner_Fuzz_FailCaller(
        uint256 _sellerPrivKey,
        uint256 _debtId,
        uint256 _price,
        uint256 _listingNonce,
        uint256 _termsExpiry
    ) public {
        vm.assume(
            _sellerPrivKey != 0 && _sellerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        address _seller = vm.addr(_sellerPrivKey);

        // Mint debt
        uint256 _sellerTokenId = _debtId.debtIdToBorrowerTokenId();
        anzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            });

        // Sign contract.
        bytes memory _sellerSignature = sponsorshipNotaryUtils
            .createSponsorshipSignature(_sellerPrivKey, _sponsorshipParams);

        // Verify and get seller.
        vm.startPrank(_seller); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );
        vm.stopPrank();
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the sponsorship
     * notary's get signer function. This test is intended to fail signature
     * validation due to the signer of the signature not being the seller.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _randomPrivKey The private key of a random address.
     * @param _debtId The debt id to sponsorship.
     * @param _price The price of the sponsorship listing.
     * @param _listingNonce The nonce of the sponsorship listing.
     * @param _termsExpiry The expiry of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testSponsorshipNotary__GetSigner_Fuzz_FailSigner(
        uint256 _sellerPrivKey,
        uint256 _randomPrivKey,
        uint256 _debtId,
        uint256 _price,
        uint256 _listingNonce,
        uint256 _termsExpiry
    ) public {
        vm.assume(
            _sellerPrivKey != 0 &&
                _randomPrivKey != 0 &&
                _sellerPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _randomPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _sellerPrivKey != _randomPrivKey
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        address _seller = vm.addr(_sellerPrivKey);

        // Mint debt
        uint256 _sellerTokenId = _debtId.debtIdToBorrowerTokenId();
        anzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            });

        // Sign contract.
        bytes memory _randomSignature = sponsorshipNotaryUtils
            .createSponsorshipSignature(_randomPrivKey, _sponsorshipParams);

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _randomSignature, //*
            anzaTokenHarness.borrowerOf
        );
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the sponsorship
     * notary's get signer function. This test is intended to fail signature
     * validation due to the collateral supplied at signature validation not
     * matching the collateral supplied at signature creation.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _debtId The debt id to sponsorship.
     * @param _price The price of the sponsorship.
     * @param _listingNonce The nonce of the sponsorship listing.
     * @param _termsExpiry The expiry of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testSponsorshipNotary__GetSigner_Fuzz_FailCollateral(
        uint256 _sellerPrivKey,
        uint256 _debtId,
        uint256 _price,
        uint256 _listingNonce,
        uint256 _termsExpiry
    ) public {
        vm.assume(
            _sellerPrivKey != 0 && _sellerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        address _seller = vm.addr(_sellerPrivKey);

        // Mint debt
        uint256 _sellerTokenId = _debtId.debtIdToBorrowerTokenId();
        anzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Mint alternate debt
        AnzaTokenHarness _altAnzaTokenHarness = new AnzaTokenHarness();
        _altAnzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            });

        // Sign contract.
        bytes memory _sellerSignature = sponsorshipNotaryUtils
            .createSponsorshipSignature(_sellerPrivKey, _sponsorshipParams);

        // Verify and get seller with invalid collateral ownerOf function.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _sellerSignature,
            _altAnzaTokenHarness.borrowerOf //*
        );
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the sponsorship
     * notary's get signer function. This test is intended to fail signature
     * validation due to the collateral terms supplied at signature validation
     * not matching the collateral supplied at signature creation.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _debtId The debt ids to sponsorship.
     * @param _price The prices of the sponsorship listing.
     * @param _listingNonce The nonces of the sponsorship listing.
     * @param _termsExpiry The expiries of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testSponsorshipNotary__GetSigner_Fuzz_FailParams(
        uint256 _sellerPrivKey,
        uint256[2] memory _debtId,
        uint256[2] memory _price,
        uint256[2] memory _listingNonce,
        uint256[2] memory _termsExpiry
    ) public {
        vm.assume(
            _sellerPrivKey != 0 && _sellerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_listingNonce[0] != _listingNonce[1]);
        vm.assume(_termsExpiry[0] != _termsExpiry[1]);
        vm.assume(_price[0] != _price[1]);
        vm.assume(_debtId[0] <= _MAX_DEBT_ID_ && _debtId[1] <= _MAX_DEBT_ID_);

        address _seller = vm.addr(_sellerPrivKey);

        // Mint debt
        uint256 _sellerTokenId = _debtId[0].debtIdToBorrowerTokenId();
        anzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Mint alternate debt
        AnzaTokenHarness _altAnzaTokenHarness = new AnzaTokenHarness();
        _altAnzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Create contract params with invalid principal
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams = ISponsorshipNotary
            .SponsorshipParams({
                price: _price[1], //*
                debtId: _debtId[0],
                listingNonce: _listingNonce[0],
                termsExpiry: _termsExpiry[0]
            });

        // Sign contract.
        bytes memory _sellerSignature = sponsorshipNotaryUtils
            .createSponsorshipSignature(_sellerPrivKey, _sponsorshipParams);

        // Change price.
        _sponsorshipParams.price = _price[0];

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid debt ID
        _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
            price: _price[0],
            debtId: _debtId[1], //*
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[0]
        });

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid nonce
        _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
            price: _price[0],
            debtId: _debtId[0],
            listingNonce: _listingNonce[1], //*
            termsExpiry: _termsExpiry[0]
        });

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid terms expiry
        _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
            price: _price[0],
            debtId: _debtId[0],
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[1] //*
        });

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = sponsorshipNotaryHarness.exposed__getSigner(
            _sponsorshipParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );
    }
}

contract SponsorshipNotaryUnitTest is SponsorshipNotaryGetSignerUnitTest {
    function setUp() public virtual override {
        SponsorshipNotaryGetSignerUnitTest.setUp();
    }
}
