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
import {AnzaRefinanceStorefront} from "@storefronts/AnzaRefinanceStorefront.sol";
import {IAnzaBaseMarketParticipant} from "@markets-databases/interfaces/IAnzaBaseMarketParticipant.sol";

import {Setup, Settings} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";

string constant SPONSORSHIP_CONTRACT_NAME = "SponsorshipNotary__test";
string constant SPONSORSHIP_CONTRACT_VERSION = "0";

contract SponsorshipNotaryHarness is SponsorshipNotary {
    constructor()
        SponsorshipNotary(SPONSORSHIP_CONTRACT_NAME, SPONSORSHIP_CONTRACT_VERSION)
    {}

    function exposed__getSigner(
        address _anzaTokenAddress,
        SponsorshipParams memory _sponsorshipParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return
            _getSigner(
                _anzaTokenAddress,
                _sponsorshipParams,
                _borrowerSignature,
                ownerOf
            );
    }

    function exposed__recoverSigner(
        address _anzaTokenAddress,
        SponsorshipParams memory _sponsorshipParams,
        bytes memory _signature
    ) internal view returns (address) {
        return _recoverSigner(_anzaTokenAddress, _sponsorshipParams, _signature);
    }
}

abstract contract LoanRefinanceInit is Setup {
    SponsorshipNotaryHarness public refinanceNotaryHarness;
    LoanRefinanceUtils public loanRefinanceUtils;
    AnzaTokenHarness public anzaTokenHarness;
    Notary.DomainSeparator internal _refinanceDomainSeparator;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        refinanceNotaryHarness = new SponsorshipNotaryHarness();

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();

        // Set Anza Debt Marketplace and Storefronts
        anzaDebtMarket = new AnzaDebtMarket();

        anzaRefinanceStorefront = new AnzaRefinanceStorefront(
            address(anzaTokenHarness),
            address(loanContract),
            address(loanTreasurer)
        );

        // Set Anza Debt Marketplace access control roles
        anzaDebtMarket.grantRole(
            _REFINANCE_STOREFRONT_,
            address(anzaRefinanceStorefront)
        );

        refinanceDomainSeparator = Notary.DomainSeparator({
            name: "AnzaRefinanceStorefront",
            version: "0",
            chainId: block.chainid,
            contractAddress: address(anzaRefinanceStorefront)
        });

        vm.stopPrank();

        _refinanceDomainSeparator = Notary.DomainSeparator({
            name: SPONSORSHIP_CONTRACT_NAME,
            version: SPONSORSHIP_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(refinanceNotaryHarness)
        });

        // Create LoanRefinanceUtils
        loanRefinanceUtils = new LoanRefinanceUtils(
            address(anzaTokenHarness),
            address(anzaDebtMarket),
            address(anzaRefinanceStorefront),
            _refinanceDomainSeparator
        );
    }
}

contract LoanRefinanceUtils is Settings {
    address private immutable __anzaTokenAddress;
    address private immutable __anzaDebtMarket;
    address private immutable __anzaRefinanceStorefrontAddress;
    Notary.DomainSeparator private __refinanceDomainSeparator;

    constructor(
        address _anzaTokenAddress,
        address _anzaDebtMarket,
        address _anzaRefinanceStorefrontAddress,
        Notary.DomainSeparator memory _refinanceDomainSeparator
    ) {
        __anzaTokenAddress = _anzaTokenAddress;
        __anzaDebtMarket = _anzaDebtMarket;
        __anzaRefinanceStorefrontAddress = _anzaRefinanceStorefrontAddress;
        __refinanceDomainSeparator = _refinanceDomainSeparator;
    }

    function createRefinanceSignature(
        uint256 _sellerPrivKey,
        ISponsorshipNotary.SponsorshipParams memory _debtSponsorshipParams
    ) public virtual returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            __anzaTokenAddress,
            _debtSponsorshipParams,
            __refinanceDomainSeparator
        );

        // Sign seller's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_sellerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function refinanceDebt(
        uint256 _debtId,
        uint256 _borrowerPrivKey
    ) public virtual returns (bool _success, bytes memory _data) {
        return
            refinanceDebt(
                _debtId,
                _borrowerPrivKey,
                ContractTerms({
                    firInterval: _FIR_INTERVAL_,
                    fixedInterestRate: _FIXED_INTEREST_RATE_,
                    isFixed: _IS_FIXED_,
                    commital: _COMMITAL_,
                    principal: _PRINCIPAL_,
                    gracePeriod: _GRACE_PERIOD_,
                    duration: _DURATION_,
                    termsExpiry: _TERMS_EXPIRY_,
                    lenderRoyalties: _LENDER_ROYALTIES_
                })
            );
    }

    function refinanceDebt(
        uint256 _debtId,
        uint256 _borrowerPrivKey,
        ContractTerms memory _contractTerms
    ) public virtual returns (bool _success, bytes memory _data) {
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        uint256 _listingNonce = IAnzaBaseMarketParticipant(
            __anzaRefinanceStorefrontAddress
        ).nonce();

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Create borrower's signature.
        bytes memory _signature = createRefinanceSignature(
            _borrowerPrivKey,
            _sponsorshipParams
        );

        // Create refinance contract.
        return
            initRefinanceContract(
                _contractTerms.principal,
                _debtId,
                _termsExpiry,
                _packedContractTerms,
                _signature
            );
    }

    function initRefinanceContract(
        uint256 _price,
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes32 _contractTerms,
        bytes memory _signature
    ) public returns (bool _success, bytes memory _data) {
        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        (_success, _data) = address(anzaDebtMarket).call{value: _price}(
            abi.encodePacked(
                __anzaRefinanceStorefrontAddress,
                abi.encodeWithSignature(
                    "buyRefinance(uint256,uint256,bytes32,bytes)",
                    _debtId,
                    _termsExpiry,
                    _contractTerms,
                    _signature
                )
            )
        );
        assertTrue(
            _success,
            "0 :: initRefinanceContract :: buyRefinance test should succeed."
        );
        vm.stopPrank();
    }
}

contract LoanRefinanceUnitTest is LoanRefinanceInit {
    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- LoanRefinance._getSigner() ---------- */
    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to pass signature validation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt id to refinance.
     * @param _listingNonce The nonce of the refinance listing.
     * @param _termsExpiry The expiry of the refinance listing.
     * @param _contractTerms The contract terms of the refinance listing.
     *
     * @dev Full pass if the function returns the correct borrower.
     */
    function testLoanRefinance__Fuzz_Pass_GetBorrower(
        uint256 _borrowerPrivKey,
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        // Mint debt
        address _borrower = vm.addr(_borrowerPrivKey);
        uint256 _borrowerTokenId = anzaTokenHarness.borrowerTokenId(_debtId);
        anzaTokenHarness.exposed__mint(_borrower, _borrowerTokenId, 1);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanRefinanceUtils
            .createRefinanceSignature(_borrowerPrivKey, _sponsorshipParams);

        // Verify and get borrower.
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        assertEq(
            _borrower,
            vm.addr(_borrowerPrivKey),
            "0 :: borrower mismatch"
        );
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to fail signature validation due
     * to the caller of the _getSigner() function being the borrower.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt id to refinance.
     * @param _listingNonce The nonce of the refinance listing.
     * @param _termsExpiry The expiry of the contract terms.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanRefinance__Fuzz_FailCaller_GetBorrower(
        uint256 _borrowerPrivKey,
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint debt
        uint256 _borrowerTokenId = anzaTokenHarness.borrowerTokenId(_debtId);
        anzaTokenHarness.exposed__mint(_borrower, _borrowerTokenId, 1);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanRefinanceUtils
            .createRefinanceSignature(_borrowerPrivKey, _sponsorshipParams);

        // Verify and get borrower.
        vm.startPrank(_borrower); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );
        vm.stopPrank();
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to fail signature validation due
     * to the signer of the signature not being the borrower.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _randomPrivKey The private key of a random address.
     * @param _debtId The debt id to refinance.
     * @param _listingNonce The nonce of the refinance listing.
     * @param _termsExpiry The expiry of the contract terms.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanRefinance__Fuzz_FailSigner_GetBorrower(
        uint256 _borrowerPrivKey,
        uint256 _randomPrivKey,
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 &&
                _randomPrivKey != 0 &&
                _borrowerPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _randomPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _borrowerPrivKey != _randomPrivKey
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint debt
        uint256 _borrowerTokenId = anzaTokenHarness.borrowerTokenId(_debtId);
        anzaTokenHarness.exposed__mint(_borrower, _borrowerTokenId, 1);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams
            memory _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _randomSignature = loanRefinanceUtils
            .createRefinanceSignature(_randomPrivKey, _sponsorshipParams);

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _randomSignature, //*
            anzaTokenHarness.borrowerOf
        );
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to fail signature validation due
     * to the collateral supplied at signature validation not matching the collateral
     * supplied at signature creation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt id to refinance.
     * @param _listingNonce The nonce of the refinance listing.
     * @param _termsExpiry The expiry of the contract terms.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanRefinance__Fuzz_FailCollateral_GetBorrower(
        uint256 _borrowerPrivKey,
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint debt
        uint256 _borrowerTokenId = anzaTokenHarness.borrowerTokenId(_debtId);
        anzaTokenHarness.exposed__mint(_borrower, _borrowerTokenId, 1);

        // Mint alternate debt
        AnzaTokenHarness _altAnzaTokenHarness = new AnzaTokenHarness();
        _altAnzaTokenHarness.exposed__mint(_borrower, _borrowerTokenId, 1);

        // Create contract params.
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams = ISponsorshipNotary
            .SponsorshipParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce, //*
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanRefinanceUtils
            .createRefinanceSignature(_borrowerPrivKey, _sponsorshipParams);

        // Verify and get borrower with invalid collateral address.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(_altAnzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Verify and get borrower with invalid collateral ownerOf function.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            _altAnzaTokenHarness.borrowerOf //*
        );
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to fail signature validation due
     * to the collateral terms supplied at signature validation not matching the
     * collateral supplied at signature creation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt ids to refinance.
     * @param _listingNonce The nonces of the refinance listing.
     * @param _termsExpiry The expiries of the contract terms.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanRefinance__Fuzz_FailTerms_GetBorrower(
        uint256 _borrowerPrivKey,
        uint256 _debtId,
        uint256[2] memory _listingNonce,
        uint256[2] memory _termsExpiry,
        ContractTerms[2] memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_listingNonce[0] != _listingNonce[1]);
        vm.assume(_termsExpiry[0] != _termsExpiry[1]);
        vm.assume(_contractTerms[0].principal != _contractTerms[1].principal);
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32[2] memory _packedContractTerms = [
            createContractTerms(_contractTerms[0]),
            createContractTerms(_contractTerms[1])
        ];

        // Mint debt
        uint256 _borrowerTokenId = anzaTokenHarness.borrowerTokenId(_debtId);
        anzaTokenHarness.exposed__mint(_borrower, _borrowerTokenId, 1);

        // Mint alternate debt
        AnzaTokenHarness _altAnzaTokenHarness = new AnzaTokenHarness();
        _altAnzaTokenHarness.exposed__mint(_borrower, _borrowerTokenId, 1);

        // Create contract params with invalid principal
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams = ISponsorshipNotary
            .SponsorshipParams({
                price: _contractTerms[1].principal, //*
                debtId: _debtId,
                listingNonce: _listingNonce[0],
                termsExpiry: _termsExpiry[0],
                contractTerms: _packedContractTerms[0]
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanRefinanceUtils
            .createRefinanceSignature(_borrowerPrivKey, _sponsorshipParams);

        // Change price.
        _sponsorshipParams.price = _contractTerms[0].principal;

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid terms
        _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[0],
            contractTerms: _packedContractTerms[1] //*
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid nonce
        _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[1], //*
            termsExpiry: _termsExpiry[0],
            contractTerms: _packedContractTerms[0]
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid terms expiry
        _sponsorshipParams = ISponsorshipNotary.SponsorshipParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[1], //*
            contractTerms: _packedContractTerms[0]
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getSigner(
            address(anzaTokenHarness),
            _sponsorshipParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );
    }
}
