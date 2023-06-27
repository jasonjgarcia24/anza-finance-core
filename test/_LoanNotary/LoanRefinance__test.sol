// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {RefinanceNotary} from "@services/LoanNotary.sol";
import {IRefinanceNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";

string constant REFINANCE_CONTRACT_NAME = "RefinanceNotary__test";
string constant REFINANCE_CONTRACT_VERSION = "0";

contract RefinanceNotaryHarness is RefinanceNotary {
    constructor()
        RefinanceNotary(REFINANCE_CONTRACT_NAME, REFINANCE_CONTRACT_VERSION)
    {}

    function exposed__getBorrower(
        address _anzaTokenAddress,
        uint256 _assetId,
        RefinanceParams memory _refinanceParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return
            _getBorrower(
                _anzaTokenAddress,
                _assetId,
                _refinanceParams,
                _borrowerSignature,
                ownerOf
            );
    }

    function exposed__recoverSigner(
        address _anzaTokenAddress,
        RefinanceParams memory _refinanceParams,
        bytes memory _signature
    ) internal view returns (address) {
        return _recoverSigner(_anzaTokenAddress, _refinanceParams, _signature);
    }
}

contract LoanRefinanceInit is Setup {
    RefinanceNotaryHarness public refinanceNotaryHarness;
    AnzaTokenHarness public anzaTokenHarness;
    Notary.DomainSeparator internal _refinanceDomainSeparator;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        refinanceNotaryHarness = new RefinanceNotaryHarness();

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();

        vm.stopPrank();

        _refinanceDomainSeparator = Notary.DomainSeparator({
            name: REFINANCE_CONTRACT_NAME,
            version: REFINANCE_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(refinanceNotaryHarness)
        });
    }
}

contract LoanRefinanceUnitTest is LoanRefinanceInit {
    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- LoanRefinance._getBorrower() ---------- */
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
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = createRefinanceSignature(
            _borrowerPrivKey,
            address(anzaTokenHarness),
            _refinanceParams,
            _refinanceDomainSeparator
        );

        // Verify and get borrower.
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
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
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to fail signature validation due
     * to the caller of the _getBorrower() function being the borrower.
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
        IRefinanceNotary.RefinanceParams
            memory _refinanceParams = IRefinanceNotary.RefinanceParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = createRefinanceSignature(
            _borrowerPrivKey,
            address(anzaTokenHarness),
            _refinanceParams,
            _refinanceDomainSeparator
        );

        // Verify and get borrower.
        vm.startPrank(_borrower); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
            _refinanceParams,
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
        IRefinanceNotary.RefinanceParams
            memory _refinanceParams = IRefinanceNotary.RefinanceParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _randomSignature = createRefinanceSignature(
            _randomPrivKey,
            address(anzaTokenHarness),
            _refinanceParams,
            _refinanceDomainSeparator
        );

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
            _refinanceParams,
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
        IRefinanceNotary.RefinanceParams memory _refinanceParams = IRefinanceNotary
            .RefinanceParams({
                price: _contractTerms.principal,
                debtId: _debtId,
                listingNonce: _listingNonce, //*
                termsExpiry: _termsExpiry,
                contractTerms: _packedContractTerms
            });

        // Sign contract.
        bytes memory _borrowerSignature = createRefinanceSignature(
            _borrowerPrivKey,
            address(anzaTokenHarness),
            _refinanceParams,
            _refinanceDomainSeparator
        );

        // Verify and get borrower with invalid collateral address.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(_altAnzaTokenHarness),
            _debtId,
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Verify and get borrower with invalid collateral ownerOf function.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
            _refinanceParams,
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
        IRefinanceNotary.RefinanceParams memory _refinanceParams = IRefinanceNotary
            .RefinanceParams({
                price: _contractTerms[1].principal, //*
                debtId: _debtId,
                listingNonce: _listingNonce[0],
                termsExpiry: _termsExpiry[0],
                contractTerms: _packedContractTerms[0]
            });

        // Sign contract.
        bytes memory _borrowerSignature = createRefinanceSignature(
            _borrowerPrivKey,
            address(anzaTokenHarness),
            _refinanceParams,
            _refinanceDomainSeparator
        );

        // Change price.
        _refinanceParams.price = _contractTerms[0].principal;

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid terms
        _refinanceParams = IRefinanceNotary.RefinanceParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[0],
            contractTerms: _packedContractTerms[1] //*
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid nonce
        _refinanceParams = IRefinanceNotary.RefinanceParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[1], //*
            termsExpiry: _termsExpiry[0],
            contractTerms: _packedContractTerms[0]
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );

        // Create contract params with invalid terms expiry
        _refinanceParams = IRefinanceNotary.RefinanceParams({
            price: _contractTerms[0].principal,
            debtId: _debtId,
            listingNonce: _listingNonce[0],
            termsExpiry: _termsExpiry[1], //*
            contractTerms: _packedContractTerms[0]
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = refinanceNotaryHarness.exposed__getBorrower(
            address(anzaTokenHarness),
            _debtId,
            _refinanceParams,
            _borrowerSignature,
            anzaTokenHarness.borrowerOf
        );
    }
}
