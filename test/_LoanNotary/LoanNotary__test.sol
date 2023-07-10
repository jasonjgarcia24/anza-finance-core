// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {LoanNotary} from "@services/LoanNotary.sol";
import {ILoanNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";

import "@test-databases/TestConstants__test.sol";
import {Setup, Settings} from "@test-base/Setup__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";

string constant NOTARY_CONTRACT_NAME = "LoanNotary__test";
string constant NOTARY_CONTRACT_VERSION = "0";

contract LoanNotaryHarness is LoanNotary {
    constructor() LoanNotary(NOTARY_CONTRACT_NAME, NOTARY_CONTRACT_VERSION) {}

    function exposed__getBorrower(
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return _getBorrower(_contractParams, _borrowerSignature, ownerOf);
    }

    function exposed__verifyBorrower(
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return _verifyBorrower(_contractParams, _borrowerSignature, ownerOf);
    }

    function exposed__recoverSigner(
        ContractParams memory _contractParams,
        bytes memory _signature
    ) internal view returns (address) {
        return _recoverSigner(_contractParams, _signature);
    }
}

abstract contract LoanNotaryInit is Setup {
    LoanNotaryHarness public loanNotaryHarness;
    LoanNotaryUtils public loanNotaryUtils;
    Notary.DomainSeparator internal _loanDomainSeparator;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        loanNotaryHarness = new LoanNotaryHarness();
        vm.stopPrank();

        _loanDomainSeparator = Notary.DomainSeparator({
            name: NOTARY_CONTRACT_NAME,
            version: NOTARY_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(loanNotaryHarness)
        });

        // Create LoanNotaryUtils.
        loanNotaryUtils = new LoanNotaryUtils(
            address(demoToken),
            _loanDomainSeparator
        );
    }
}

contract LoanNotaryUtils is Settings {
    address internal immutable _demoTokenAddress;
    Notary.DomainSeparator private __loanDomainSeparator;

    constructor(
        address _demoTokenAddress_,
        Notary.DomainSeparator memory _loanDomainSeparator
    ) {
        _demoTokenAddress = _demoTokenAddress_;
        __loanDomainSeparator = _loanDomainSeparator;
    }

    /**
     * Create contract signature for default contract values.
     *
     * @param _borrowerPrivKey The borrower's private key.
     * @param _collateralId The collateral's token ID.
     *
     * @return _signature The signed contract.
     */
    function createContractSignature(
        uint256 _borrowerPrivKey,
        uint256 _collateralId
    ) public returns (bytes memory _signature) {
        uint256 _collateralNonce = loanContract.collateralNonce(
            _demoTokenAddress,
            _collateralId
        );

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _PRINCIPAL_,
                contractTerms: createContractTerms(),
                collateralAddress: _demoTokenAddress,
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Create message for signing
        bytes32 _message = Notary.typeDataHash(
            _contractParams,
            __loanDomainSeparator
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_borrowerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    /**
     * Create contract signature for provided contract values.
     *
     * @param _borrowerPrivKey The borrower's private key.
     * @param _contractParams The contract parameters.
     *
     * @return _signature The signed contract.
     */
    function createContractSignature(
        uint256 _borrowerPrivKey,
        ILoanNotary.ContractParams memory _contractParams
    ) public view returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            _contractParams,
            __loanDomainSeparator
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_borrowerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    /**
     * Create contract signature for provided contract values and domain separator.
     *
     * @param _borrowerPrivKey The borrower's private key.
     * @param _loanDomainSeparator The loan domain separator.
     * @param _contractParams The contract parameters.
     *
     * @return _signature The signed contract.
     */
    function createContractSignature(
        uint256 _borrowerPrivKey,
        Notary.DomainSeparator memory _loanDomainSeparator,
        ILoanNotary.ContractParams memory _contractParams
    ) public pure returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            _contractParams,
            _loanDomainSeparator
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_borrowerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }
}

abstract contract LoanNotaryGetBorrowerUnitTest is LoanNotaryInit {
    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- LoanNotary._getBorrower() ---------- */
    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to pass signature validation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     *
     * @dev Full pass if the function returns the correct borrower.
     */
    function testLoanNotary__GetBorrower_Fuzz_Pass(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanNotaryUtils
            .createContractSignature(
                _borrowerPrivKey,
                _loanDomainSeparator,
                _contractParams
            );

        // Verify and get borrower.
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams,
            _borrowerSignature,
            _demoToken.ownerOf
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
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__GetBorrower_Fuzz_FailCaller(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanNotaryUtils
            .createContractSignature(_borrowerPrivKey, _contractParams);

        // Verify and get borrower.
        vm.startPrank(_borrower); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams,
            _borrowerSignature,
            _demoToken.ownerOf
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
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__GetBorrower_Fuzz_FailSigner(
        uint256 _borrowerPrivKey,
        uint256 _randomPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 &&
                _randomPrivKey != 0 &&
                _borrowerPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _randomPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _borrowerPrivKey != _randomPrivKey
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _randomSignature = loanNotaryUtils.createContractSignature(
            _randomPrivKey,
            _contractParams
        );

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams,
            _randomSignature, //*
            _demoToken.ownerOf
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
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _altCollateralNonce The alternate nonce of the collateral.
     * @param _contractTerms The contract terms.
     * @param _altContractTerms The alternate contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__GetBorrower_Fuzz_FailTerms(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        uint256 _altCollateralNonce,
        ContractTerms memory _contractTerms,
        ContractTerms memory _altContractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_collateralNonce != _altCollateralNonce);
        vm.assume(_contractTerms.principal != _altContractTerms.principal);

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        bytes32 _altPackedContractTerms = createContractTerms(
            _altContractTerms
        );

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Mint collateral
        DemoToken _altDemoToken = new DemoToken(0);
        _altDemoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanNotaryUtils
            .createContractSignature(_borrowerPrivKey, _contractParams);

        // Contract params with invalid principal
        _contractParams.principal = _altContractTerms.principal; //*

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid terms.
        _contractParams.principal = _contractTerms.principal;
        _contractParams.contractTerms = _altPackedContractTerms; //*

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid collateral address
        _contractParams.contractTerms = _packedContractTerms;
        _contractParams.collateralAddress = address(_altDemoToken); //*

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid collateral id
        _contractParams.collateralAddress = address(_demoToken);
        unchecked {
            // Allow overflow
            _contractParams.collateralId = _collateralId + 1; //*
        }

        // Verify and get borrower.
        vm.expectRevert("ERC721: invalid token ID");
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid collateral nonce
        _contractParams.collateralId = _collateralId;
        _contractParams.collateralNonce = _altCollateralNonce; //*

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );
    }
}

abstract contract LoanNotaryVerifyBorrowerUnitTest is LoanNotaryInit {
    function setUp() public virtual override {
        super.setUp();
    }

    /* ---------- LoanNotary._verifyBorrower() ---------- */
    /**
     * Test the verify borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * verify borrower function. This test is intended to pass signature validation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     *
     * @dev Full pass if the function returns the correct borrower.
     */
    function testLoanNotary__VerifyBorrower_Fuzz_Pass(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanNotaryUtils
            .createContractSignature(
                _borrowerPrivKey,
                _loanDomainSeparator,
                _contractParams
            );

        // Verify and get borrower.
        vm.startPrank(_borrower);
        assertEq(
            loanNotaryHarness.exposed__verifyBorrower(
                _contractParams,
                _borrowerSignature,
                _demoToken.ownerOf
            ),
            vm.addr(_borrowerPrivKey),
            "0 :: borrower mismatch"
        );
        vm.stopPrank();
    }

    /**
     * Test the verify borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * verify borrower function. This test is intended to fail signature validation due
     * to the caller of the _verifyBorrower() function being the borrower.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__VerifyBorrower_Fuzz_FailCaller(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanNotaryUtils
            .createContractSignature(_borrowerPrivKey, _contractParams);

        // Verify and get borrower.
        vm.startPrank(admin); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__verifyBorrower(
            _contractParams,
            _borrowerSignature,
            _demoToken.ownerOf
        );
        vm.stopPrank();
    }

    /**
     * Test the verify borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * verify borrower function. This test is intended to fail signature validation due
     * to the signer of the signature not being the borrower.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _randomPrivKey The private key of a random address.
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__VerifyBorrower_Fuzz_FailSigner(
        uint256 _borrowerPrivKey,
        uint256 _randomPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 &&
                _randomPrivKey != 0 &&
                _borrowerPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _randomPrivKey < _SECP256K1_CURVE_ORDER_ &&
                _borrowerPrivKey != _randomPrivKey
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _randomSignature = loanNotaryUtils.createContractSignature(
            _randomPrivKey,
            _contractParams
        );

        // Verify and get borrower.
        vm.startPrank(_borrower);
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__verifyBorrower(
            _contractParams,
            _randomSignature, //*
            _demoToken.ownerOf
        );
        vm.stopPrank();
    }

    /**
     * Test the verify borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * verify borrower function. This test is intended to fail signature validation due
     * to the collateral terms supplied at signature validation not matching the
     * collateral supplied at signature creation.
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _altCollateralNonce The alternate nonce of the collateral.
     * @param _contractTerms The contract terms.
     * @param _altContractTerms The alternate contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__VerifyBorrower_Fuzz_FailTerms(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        uint256 _collateralNonce,
        uint256 _altCollateralNonce,
        ContractTerms memory _contractTerms,
        ContractTerms memory _altContractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );
        vm.assume(_collateralNonce != _altCollateralNonce);
        vm.assume(_contractTerms.principal != _altContractTerms.principal);

        address _borrower = vm.addr(_borrowerPrivKey);

        // Pack contract terms.
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        bytes32 _altPackedContractTerms = createContractTerms(
            _altContractTerms
        );

        // Mint collateral
        DemoToken _demoToken = new DemoToken(0);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Mint collateral
        DemoToken _altDemoToken = new DemoToken(0);
        _altDemoToken.exposed__mint(_borrower, _collateralId);

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Sign contract.
        bytes memory _borrowerSignature = loanNotaryUtils
            .createContractSignature(_borrowerPrivKey, _contractParams);

        // Contract params with invalid principal
        _contractParams.principal = _altContractTerms.principal; //*

        // Verify and get borrower.
        vm.startPrank(_borrower);
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        loanNotaryHarness.exposed__verifyBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid terms.
        _contractParams.principal = _contractTerms.principal;
        _contractParams.contractTerms = _altPackedContractTerms; //*

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        loanNotaryHarness.exposed__verifyBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid collateral address
        _contractParams.contractTerms = _packedContractTerms;
        _contractParams.collateralAddress = address(_altDemoToken); //*

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        loanNotaryHarness.exposed__verifyBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid collateral id
        _contractParams.collateralAddress = address(_demoToken);
        unchecked {
            // Allow overflow
            _contractParams.collateralId = _collateralId + 1; //*
        }

        // Verify and get borrower.
        vm.expectRevert("ERC721: invalid token ID");
        loanNotaryHarness.exposed__verifyBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Contract params with invalid collateral nonce
        _contractParams.collateralId = _collateralId;
        _contractParams.collateralNonce = _altCollateralNonce; //*

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        loanNotaryHarness.exposed__verifyBorrower(
            _contractParams, //*
            _borrowerSignature,
            _demoToken.ownerOf
        );
        vm.stopPrank();
    }
}

contract LoanNotaryUnitTest is
    LoanNotaryGetBorrowerUnitTest,
    LoanNotaryVerifyBorrowerUnitTest
{
    function setUp()
        public
        virtual
        override(
            LoanNotaryGetBorrowerUnitTest,
            LoanNotaryVerifyBorrowerUnitTest
        )
    {
        LoanNotaryInit.setUp();
    }
}
