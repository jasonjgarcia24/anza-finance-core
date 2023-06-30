// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";
import "@markets-constants/AnzaDebtMarketRoles.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {RefinanceNotary} from "@services/LoanNotary.sol";
import {IRefinanceNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";
import {AnzaDebtMarket} from "@markets/AnzaDebtMarket.sol";
import {AnzaRefinanceStorefront} from "@storefronts/AnzaRefinanceStorefront.sol";
import {IAnzaBaseMarketParticipant} from "@markets-databases/interfaces/IAnzaBaseMarketParticipant.sol";

import {Setup, Settings} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";

string constant REFINANCE_CONTRACT_NAME = "RefinanceNotary__test";
string constant REFINANCE_CONTRACT_VERSION = "0";

contract RefinanceNotaryHarness is RefinanceNotary {
    constructor(
        address _anzaTokenHarnessAddress
    )
        RefinanceNotary(
            REFINANCE_CONTRACT_NAME,
            REFINANCE_CONTRACT_VERSION,
            _anzaTokenHarnessAddress
        )
    {}

    function exposed__getBorrower(
        RefinanceParams memory _refinanceParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return _getBorrower(_refinanceParams, _borrowerSignature, ownerOf);
    }

    function exposed__recoverSigner(
        RefinanceParams memory _refinanceParams,
        bytes memory _signature
    ) internal view returns (address) {
        return _recoverSigner(_refinanceParams, _signature);
    }
}

abstract contract RefinanceNotaryInit is Setup {
    RefinanceNotaryHarness public refinanceNotaryHarness;
    RefinanceNotaryUtils public refinanceNotaryUtils;
    AnzaTokenHarness public anzaTokenHarness;
    Notary.DomainSeparator internal _refinanceDomainSeparator;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        // Set AnzaTokenHarness
        anzaTokenHarness = new AnzaTokenHarness();

        // Set RefinanceNotaryHarness
        refinanceNotaryHarness = new RefinanceNotaryHarness(
            address(anzaTokenHarness)
        );

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
            name: REFINANCE_CONTRACT_NAME,
            version: REFINANCE_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(refinanceNotaryHarness)
        });

        // Create RefinanceNotaryUtils
        refinanceNotaryUtils = new RefinanceNotaryUtils(
            address(anzaTokenHarness),
            address(anzaDebtMarket),
            address(anzaRefinanceStorefront),
            _refinanceDomainSeparator
        );
    }
}

contract RefinanceNotaryUtils is Settings {
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
        IRefinanceNotary.RefinanceParams memory _debtRefinanceParams
    ) public virtual returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            __anzaTokenAddress,
            _debtRefinanceParams,
            __refinanceDomainSeparator
        );

        // Sign seller's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_sellerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }
}

abstract contract RefinanceNotaryGetBorrowererUnitTest is RefinanceNotaryInit {
    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- RefinanceNotary._getBorrower() ---------- */
    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the refinance
     * notary's get borrower function. This test is intended to pass signature
     * validation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt id to refinance.
     * @param _listingNonce The nonce of the refinance listing.
     * @param _termsExpiry The expiry of the refinance listing.
     * @param _contractTerms The contract terms of the refinance listing.
     *
     * @dev Full pass if the function returns the correct borrower.
     */
    function testRefinanceNotary__GetBorrower_Fuzz_Pass(
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
        IRefinanceNotary.RefinanceParams
            memory _refinanceParams = IRefinanceNotary.RefinanceParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = refinanceNotaryUtils
            .createRefinanceSignature(_borrowerPrivKey, _refinanceParams);

        // Verify and get borrower.
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            _refinanceParams,
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
     * This test is a fuzz test that generates random inputs for the refinance
     * notary's get borrower function. This test is intended to fail signature
     * validation due to the caller of the _getBorrower() function being the
     * borrower.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt id to refinance.
     * @param _listingNonce The nonce of the refinance listing.
     * @param _termsExpiry The expiry of the contract terms.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testRefinanceNotary__GetBorrower_Fuzz_FailCaller(
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
        IRefinanceNotary.RefinanceParams
            memory _refinanceParams = IRefinanceNotary.RefinanceParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = refinanceNotaryUtils
            .createRefinanceSignature(_borrowerPrivKey, _refinanceParams);

        // Verify and get borrower.
        vm.startPrank(_borrower); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );
        vm.stopPrank();
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the refinance
     * notary's get borrower function. This test is intended to fail signature
     * validation due to the signer of the signature not being the borrower.
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
    function testRefinanceNotary__GetBorrower_Fuzz_FailSigner(
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
        IRefinanceNotary.RefinanceParams
            memory _refinanceParams = IRefinanceNotary.RefinanceParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _randomSignature = refinanceNotaryUtils
            .createRefinanceSignature(_randomPrivKey, _refinanceParams);

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            _refinanceParams,
            _randomSignature, //*
            anzaTokenHarness.borrowerOf
        );
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the refinance
     * notary's get borrower function. This test is intended to fail signature
     * validation due to the collateral supplied at signature validation not
     * matching the collateral supplied at signature creation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt id to refinance.
     * @param _listingNonce The nonce of the refinance listing.
     * @param _termsExpiry The expiry of the contract terms.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testRefinanceNotary__GetBorrower_Fuzz_FailCollateral(
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
        IRefinanceNotary.RefinanceParams memory _refinanceParams = IRefinanceNotary
            .RefinanceParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce, //*
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = refinanceNotaryUtils
            .createRefinanceSignature(_borrowerPrivKey, _refinanceParams);

        // Verify and get borrower with invalid collateral ownerOf function.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            _refinanceParams,
            _borrowerSignature,
            _altAnzaTokenHarness.borrowerOf //*
        );
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the refinance
     * notary's get borrower function. This test is intended to fail signature
     * validation due to the collateral terms supplied at signature validation
     * not matching the collateral supplied at signature creation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _debtId The debt ids to refinance.
     * @param _listingNonce The nonces of the refinance listing.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testRefinanceNotary__GetBorrower_Fuzz_FailTerms(
        uint256 _borrowerPrivKey,
        uint256 _debtId,
        uint256[2] memory _listingNonce,
        ContractTerms[2] memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_listingNonce[0] != _listingNonce[1]);
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
        IRefinanceNotary.RefinanceParams memory _refinanceParams = IRefinanceNotary
            .RefinanceParams({
                price: _contractTerms[1].principal, //*
                debtId: _debtId,
                listingNonce: _listingNonce[0],
                contractTerms: _packedContractTerms[0]
            });

        // Sign contract.
        bytes memory _borrowerSignature = refinanceNotaryUtils
            .createRefinanceSignature(_borrowerPrivKey, _refinanceParams);

        // Change price.
        _refinanceParams.price = _contractTerms[0].principal;

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid terms
        _refinanceParams = IRefinanceNotary.RefinanceParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[0],
            contractTerms: _packedContractTerms[1] //*
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid nonce
        _refinanceParams = IRefinanceNotary.RefinanceParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[1], //*
            contractTerms: _packedContractTerms[0]
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );
    }
}

contract RefinanceNotaryUnitTest is RefinanceNotaryGetBorrowererUnitTest {
    function setUp() public virtual override {
        RefinanceNotaryGetBorrowererUnitTest.setUp();
    }
}
