// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";
import "@markets-constants/AnzaDebtMarketRoles.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {DebtNotary} from "@services/LoanNotary.sol";
import {IDebtNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";
import {AnzaDebtMarket} from "@markets/AnzaDebtMarket.sol";
import {AnzaDebtStorefront} from "@storefronts/AnzaDebtStorefront.sol";
import {IAnzaBaseMarketParticipant} from "@markets-databases/interfaces/IAnzaBaseMarketParticipant.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

import "@test-databases/TestConstants__test.sol";
import {Setup, Settings} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";

string constant DEBT_CONTRACT_NAME = "DebtNotary__test";
string constant DEBT_CONTRACT_VERSION = "0";

contract DebtNotaryHarness is DebtNotary {
    constructor(
        address _anzaTokenHarnessAddress
    )
        DebtNotary(
            DEBT_CONTRACT_NAME,
            DEBT_CONTRACT_VERSION,
            _anzaTokenHarnessAddress
        )
    {}

    function exposed__getSigner(
        uint256 _assetId,
        DebtParams memory _debtParams,
        bytes memory _sellerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return _getSigner(_assetId, _debtParams, _sellerSignature, ownerOf);
    }

    function exposed__recoverSigner(
        DebtParams memory _debtParams,
        bytes memory _signature
    ) internal view returns (address) {
        return _recoverSigner(_debtParams, _signature);
    }
}

abstract contract DebtNotaryInit is Setup {
    DebtNotaryHarness public debtNotaryHarness;
    DebtNotaryUtils public debtNotaryUtils;
    AnzaTokenHarness public anzaTokenHarness;
    Notary.DomainSeparator internal _debtDomainSeparator;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        // Set AnzaTokenHarness
        anzaTokenHarness = new AnzaTokenHarness();

        // Set DebtNotaryHarness
        debtNotaryHarness = new DebtNotaryHarness(address(anzaTokenHarness));

        // Set Anza Debt Marketplace and Storefronts
        anzaDebtMarket = new AnzaDebtMarket();

        anzaDebtStorefront = new AnzaDebtStorefront(
            address(anzaTokenHarness),
            address(loanContract),
            address(loanTreasurer)
        );

        // Set Anza Debt Marketplace access control roles
        anzaDebtMarket.grantRole(
            _DEBT_STOREFRONT_,
            address(anzaDebtStorefront)
        );

        debtDomainSeparator = Notary.DomainSeparator({
            name: "AnzaDebtStorefront",
            version: "0",
            chainId: block.chainid,
            contractAddress: address(anzaDebtStorefront)
        });

        vm.stopPrank();

        _debtDomainSeparator = Notary.DomainSeparator({
            name: DEBT_CONTRACT_NAME,
            version: DEBT_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(debtNotaryHarness)
        });

        // Create DebtNotaryUtils
        debtNotaryUtils = new DebtNotaryUtils(
            address(anzaTokenHarness),
            address(anzaDebtMarket),
            address(anzaDebtStorefront),
            _debtDomainSeparator
        );
    }
}

contract DebtNotaryUtils is Settings {
    address private immutable __anzaTokenAddress;
    address private immutable __anzaDebtMarket;
    address private immutable __anzaDebtStorefrontAddress;
    Notary.DomainSeparator private __debtDomainSeparator;

    constructor(
        address _anzaTokenAddress,
        address _anzaDebtMarket,
        address _anzaDebtStorefrontAddress,
        Notary.DomainSeparator memory _debtDomainSeparator
    ) {
        __anzaTokenAddress = _anzaTokenAddress;
        __anzaDebtMarket = _anzaDebtMarket;
        __anzaDebtStorefrontAddress = _anzaDebtStorefrontAddress;
        __debtDomainSeparator = _debtDomainSeparator;
    }

    function createDebtSignature(
        uint256 _sellerPrivKey,
        IDebtNotary.DebtParams memory _debtParams
    ) public virtual returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            _debtParams,
            __debtDomainSeparator
        );

        // Sign seller's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_sellerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function purchaseDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _sellerPrivKey
    ) public virtual returns (bool _success, bytes memory _data) {
        return
            purchaseDebt(
                _collateralAddress,
                _collateralId,
                _sellerPrivKey,
                ContractTerms({
                    firInterval: _FIR_INTERVAL_,
                    fixedInterestRate: _FIXED_INTEREST_RATE_,
                    isFixed: _IS_FIXED_,
                    commital: _COMMITAL_,
                    commitalDuration: 0,
                    principal: _PRINCIPAL_,
                    gracePeriod: _GRACE_PERIOD_,
                    duration: _DURATION_,
                    termsExpiry: _TERMS_EXPIRY_,
                    lenderRoyalties: _LENDER_ROYALTIES_
                })
            );
    }

    function purchaseDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _sellerPrivKey,
        ContractTerms memory _contractTerms
    ) public virtual returns (bool _success, bytes memory _data) {
        uint256 _termsExpiry = uint256(_TERMS_EXPIRY_);
        uint256 _listingNonce = IAnzaBaseMarketParticipant(
            __anzaDebtStorefrontAddress
        ).nonce();

        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        // Create contract params.
        IDebtNotary.DebtParams memory _debtParams = IDebtNotary.DebtParams({
            price: _PRINCIPAL_,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            listingNonce: _listingNonce,
            termsExpiry: _termsExpiry
        });

        // Create seller's signature.
        bytes memory _signature = createDebtSignature(
            _sellerPrivKey,
            _debtParams
        );

        // Create debt contract.
        return
            initDebtContract(
                _contractTerms.principal,
                _collateralAddress,
                _collateralId,
                _termsExpiry,
                _packedContractTerms,
                _signature
            );
    }

    function initDebtContract(
        uint256 _price,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _termsExpiry,
        bytes32 _packedContractTerms,
        bytes memory _signature
    ) public returns (bool _success, bytes memory _data) {
        vm.deal(alt_account, 4 ether);
        vm.startPrank(alt_account);
        (_success, _data) = address(anzaDebtMarket).call{value: _price}(
            abi.encodePacked(
                __anzaDebtStorefrontAddress,
                abi.encodeWithSignature(
                    "buyDebt(address,uint256,uint256,bytes32,bytes)",
                    _collateralAddress,
                    _collateralId,
                    _termsExpiry,
                    _packedContractTerms,
                    _signature
                )
            )
        );
        assertTrue(
            _success,
            "0 :: initDebtContract :: buyDebt test should succeed."
        );
        vm.stopPrank();
    }
}

abstract contract DebtNotaryGetSignerUnitTest is DebtNotaryInit {
    using AnzaTokenIndexer for uint256;

    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- DebtNotary._getSigner() ---------- */
    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the debt notary's
     * get signer function. This test is intended to pass signature validation.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _debtId The id of the debt.
     * @param _collateralAddress The address of the collateral.
     * @param _collateralId The id of the collateral.
     * @param _price The price of the debt listing.
     * @param _listingNonce The nonce of the debt listing.
     * @param _termsExpiry The expiry of the debt listing.
     *
     * @dev Full pass if the function returns the correct seller.
     */
    function testDebtNotary__GetSigner_Fuzz_Pass(
        uint256 _sellerPrivKey,
        uint256 _debtId,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _price,
        uint256 _listingNonce,
        uint256 _termsExpiry
    ) public {
        vm.assume(
            _sellerPrivKey != 0 && _sellerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_collateralAddress != address(0));
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        // Mint debt
        address _seller = vm.addr(_sellerPrivKey);
        uint256 _sellerTokenId = _debtId.debtIdToBorrowerTokenId();
        anzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Create contract params.
        IDebtNotary.DebtParams memory _debtParams = IDebtNotary.DebtParams({
            price: _price,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            listingNonce: _listingNonce,
            termsExpiry: _termsExpiry
        });

        // Sign contract.
        bytes memory _sellerSignature = debtNotaryUtils.createDebtSignature(
            _sellerPrivKey,
            _debtParams
        );

        // Verify and get seller.
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        assertEq(_seller, vm.addr(_sellerPrivKey), "0 :: seller mismatch");
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the debt notary's
     * get signer function. This test is intended to fail signature validation due
     * to the caller of the _getSigner() function being the seller.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _debtId The id of the debt.
     * @param _collateralAddress The address of the collateral.
     * @param _collateralId The id of the collateral.
     * @param _price The price of the debt listing.
     * @param _listingNonce The nonce of the debt listing.
     * @param _termsExpiry The expiry of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testDebtNotary__GetSigner_Fuzz_FailCaller(
        uint256 _sellerPrivKey,
        uint256 _debtId,
        address _collateralAddress,
        uint256 _collateralId,
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
        IDebtNotary.DebtParams memory _debtParams = IDebtNotary.DebtParams({
            price: _price,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            listingNonce: _listingNonce,
            termsExpiry: _termsExpiry
        });

        // Sign contract.
        bytes memory _sellerSignature = debtNotaryUtils.createDebtSignature(
            _sellerPrivKey,
            _debtParams
        );

        // Verify and get seller.
        vm.startPrank(_seller); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );
        vm.stopPrank();
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the debt notary's
     * get signer function. This test is intended to fail signature validation due
     * to the signer of the signature not being the seller.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _randomPrivKey The private key of a random address.
     * @param _debtId The id of the debt.
     * @param _collateralAddress The address of the collateral.
     * @param _collateralId The id of the collateral.
     * @param _price The price of the debt listing.
     * @param _listingNonce The nonce of the debt listing.
     * @param _termsExpiry The expiry of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testDebtNotary__GetSigner_Fuzz_FailSigner(
        uint256 _sellerPrivKey,
        uint256 _randomPrivKey,
        uint256 _debtId,
        address _collateralAddress,
        uint256 _collateralId,
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
        IDebtNotary.DebtParams memory _debtParams = IDebtNotary.DebtParams({
            price: _price,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            listingNonce: _listingNonce,
            termsExpiry: _termsExpiry
        });

        // Sign contract.
        bytes memory _randomSignature = debtNotaryUtils.createDebtSignature(
            _randomPrivKey,
            _debtParams
        );

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _randomSignature, //*
            anzaTokenHarness.borrowerOf
        );
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the debt notary's
     * get signer function. This test is intended to fail signature validation due
     * to the collateral supplied at signature validation not matching the collateral
     * supplied at signature creation.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _collateralAddress The address of the collateral.
     * @param _debtId The id of the debt.
     * @param _collateralId The id of the collateral.
     * @param _price The price of the debt.
     * @param _listingNonce The nonce of the debt listing.
     * @param _termsExpiry The expiry of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testDebtNotary__GetSigner_Fuzz_FailCollateral(
        uint256 _sellerPrivKey,
        uint256 _debtId,
        address _collateralAddress,
        uint256 _collateralId,
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
        IDebtNotary.DebtParams memory _debtParams = IDebtNotary.DebtParams({
            price: _price,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            listingNonce: _listingNonce,
            termsExpiry: _termsExpiry
        });

        // Sign contract.
        bytes memory _sellerSignature = debtNotaryUtils.createDebtSignature(
            _sellerPrivKey,
            _debtParams
        );

        // Verify and get seller with invalid collateral ownerOf function.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            _altAnzaTokenHarness.borrowerOf //*
        );
    }

    /**
     * Test the get signer function.
     *
     * This test is a fuzz test that generates random inputs for the debt notary's
     * get signer function. This test is intended to fail signature validation due
     * to the collateral terms supplied at signature validation not matching the
     * collateral supplied at signature creation.
     *
     * @param _sellerPrivKey The private key of the seller.
     * @param _debtId The id of the debt.
     * @param _collateralAddress The collateral addresses of the debt listing.
     * @param _collateralId The collateral ids of the debt listing.
     * @param _price The prices of the debt listing.
     * @param _listingNonce The nonces of the debt listing.
     * @param _termsExpiry The expiries of the contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testDebtNotary__GetSigner_Fuzz_FailParams(
        uint256 _sellerPrivKey,
        uint256 _debtId,
        address[2] memory _collateralAddress,
        uint256[2] memory _collateralId,
        uint256[2] memory _price,
        uint256[2] memory _listingNonce,
        uint256[2] memory _termsExpiry
    ) public {
        vm.assume(
            _sellerPrivKey != 0 && _sellerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        vm.assume(_listingNonce[0] != _listingNonce[1]);
        vm.assume(_termsExpiry[0] != _termsExpiry[1]);
        vm.assume(_price[0] != _price[1]);

        address _seller = vm.addr(_sellerPrivKey);

        // Mint debt
        uint256 _sellerTokenId = _debtId.debtIdToBorrowerTokenId();
        anzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Mint alternate debt
        AnzaTokenHarness _altAnzaTokenHarness = new AnzaTokenHarness();
        _altAnzaTokenHarness.exposed__mint(_seller, _sellerTokenId, 1);

        // Create contract params with invalid principal
        IDebtNotary.DebtParams memory _debtParams = IDebtNotary.DebtParams({
            price: _price[1], //*
            collateralAddress: _collateralAddress[0],
            collateralId: _collateralId[0],
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[0]
        });

        // Sign contract.
        bytes memory _sellerSignature = debtNotaryUtils.createDebtSignature(
            _sellerPrivKey,
            _debtParams
        );

        // Change price.
        _debtParams.price = _price[0];

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid collateral address
        _debtParams = IDebtNotary.DebtParams({
            price: _price[0],
            collateralAddress: _collateralAddress[1], //*
            collateralId: _collateralId[0],
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[0]
        });

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid collateral ID
        _debtParams = IDebtNotary.DebtParams({
            price: _price[0],
            collateralAddress: _collateralAddress[0],
            collateralId: _collateralId[1], //*
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[0]
        });

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid nonce
        _debtParams = IDebtNotary.DebtParams({
            price: _price[0],
            collateralAddress: _collateralAddress[0],
            collateralId: _collateralId[0],
            listingNonce: _listingNonce[1], //*
            termsExpiry: _termsExpiry[0]
        });

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid terms expiry
        _debtParams = IDebtNotary.DebtParams({
            price: _price[0],
            collateralAddress: _collateralAddress[0],
            collateralId: _collateralId[0],
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[1] //*
        });

        // Verify and get seller.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _seller = debtNotaryHarness.exposed__getSigner(
            _debtId,
            _debtParams,
            _sellerSignature,
            anzaTokenHarness.borrowerOf
        );
    }
}

contract DebtNotaryUnitTest is DebtNotaryGetSignerUnitTest {
    function setUp() public virtual override {
        DebtNotaryGetSignerUnitTest.setUp();
    }
}
