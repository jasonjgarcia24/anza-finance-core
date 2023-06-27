// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {LoanNotary} from "@services/LoanNotary.sol";
import {ILoanNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";

string constant NOTARY_CONTRACT_NAME = "LoanNotary__test";
string constant NOTARY_CONTRACT_VERSION = "0";

contract LoanNotaryHarness is LoanNotary {
    constructor() LoanNotary(NOTARY_CONTRACT_NAME, NOTARY_CONTRACT_VERSION) {}

    function exposed__getBorrower(
        uint256 _assetId,
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return
            _getBorrower(
                _assetId,
                _contractParams,
                _borrowerSignature,
                ownerOf
            );
    }

    function exposed__verifyBorrower(
        uint256 _assetId,
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) public view returns (address) {
        return
            _verifyBorrower(
                _assetId,
                _contractParams,
                _borrowerSignature,
                ownerOf
            );
    }

    function exposed__recoverSigner(
        ContractParams memory _contractParams,
        bytes memory _signature
    ) internal view returns (address) {
        return _recoverSigner(_contractParams, _signature);
    }
}

contract LoanNotaryInit is Setup {
    LoanNotaryHarness public loanNotaryHarness;
    Notary.DomainSeparator public notaryDomainSeparator;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        loanNotaryHarness = new LoanNotaryHarness();
        vm.stopPrank();

        notaryDomainSeparator = Notary.DomainSeparator({
            name: NOTARY_CONTRACT_NAME,
            version: NOTARY_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(loanNotaryHarness)
        });
    }
}

contract LoanNotaryUnitTest is LoanNotaryInit {
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
    function testLoanNotary__Fuzz_Pass_GetBorrower(
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

        // Sign contract.
        bytes memory _borrowerSignature = createContractSignature(
            _borrowerPrivKey,
            _contractTerms.principal,
            address(_demoToken),
            _collateralId,
            _collateralNonce,
            _packedContractTerms,
            notaryDomainSeparator
        );

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Verify and get borrower.
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
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
    function testLoanNotary__Fuzz_FailCaller_GetBorrower(
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

        // Sign contract.
        bytes memory _borrowerSignature = createContractSignature(
            _borrowerPrivKey,
            _contractTerms.principal,
            address(_demoToken),
            _collateralId,
            _collateralNonce,
            _packedContractTerms,
            notaryDomainSeparator
        );

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Verify and get borrower.
        vm.startPrank(_borrower); //*
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
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
    function testLoanNotary__Fuzz_FailSigner_GetBorrower(
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

        // Sign contract.
        bytes memory _randomSignature = createContractSignature(
            _randomPrivKey,
            _contractTerms.principal,
            address(_demoToken),
            _collateralId,
            _collateralNonce,
            _packedContractTerms,
            notaryDomainSeparator
        );

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
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
     * to the collateral supplied at signature validation not matching the collateral
     * supplied at signature creation (i.e. "fail downstream").
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__Fuzz_FailCollateralDownstream_GetBorrower(
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

        // Mint alternate collateral
        DemoToken _altDemoToken = new DemoToken(0);
        _altDemoToken.exposed__mint(_borrower, _collateralId);

        // Sign contract.
        bytes memory _borrowerSignature = createContractSignature(
            _borrowerPrivKey,
            _contractTerms.principal,
            address(_demoToken),
            _collateralId,
            _collateralNonce,
            _packedContractTerms,
            notaryDomainSeparator
        );

        // Create contract params with invalid collateral.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_altDemoToken), //*
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
            _contractParams,
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Create contract params.
        _contractParams = ILoanNotary.ContractParams({
            principal: _contractTerms.principal,
            contractTerms: _packedContractTerms,
            collateralAddress: address(_demoToken),
            collateralId: _collateralId,
            collateralNonce: _collateralNonce
        });

        // Verify and get borrower with invalid collateral ownerOf function.
        vm.expectRevert(StdNotaryErrors.InvalidOwnerMethod.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
            _contractParams,
            _borrowerSignature,
            _altDemoToken.ownerOf //*
        );
    }

    /**
     * Test the get borrower function.
     *
     * This test is a fuzz test that generates random inputs for the loan notary's
     * get borrower function. This test is intended to fail signature validation due
     * to the collateral supplied at signature creation not matching the collateral
     * supplied at signature validation (i.e. "fail upstream").
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _collateralNonce The nonce of the collateral.
     * @param _contractTerms The contract terms.
     *
     * @dev Full pass if the function reverts as expected.
     */
    function testLoanNotary__Fuzz_FailCollateralUpstream_GetBorrower(
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

        // Mint alternate collateral
        uint256 _altCollateralId = _collateralId;
        DemoToken _altDemoToken = new DemoToken(0);
        _altDemoToken.exposed__mint(_borrower, _altCollateralId);

        // Sign contract with invalid collateral address.
        bytes memory _borrowerSignature = createContractSignature(
            _borrowerPrivKey,
            _contractTerms.principal,
            address(_altDemoToken), //*
            _collateralId,
            _collateralNonce,
            _packedContractTerms,
            notaryDomainSeparator
        );

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
            _contractParams,
            _borrowerSignature,
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
    function testLoanNotary__Fuzz_FailTerms_GetBorrower(
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

        // Sign contract.
        bytes memory _borrowerSignature = createContractSignature(
            _borrowerPrivKey,
            _contractTerms.principal,
            address(_demoToken),
            _collateralId,
            _collateralNonce,
            _packedContractTerms,
            notaryDomainSeparator
        );

        // Create contract params with invalid principal
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _altContractTerms.principal, //*
                contractTerms: _packedContractTerms,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
            _contractParams,
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Create contract params with invalid terms
        _contractParams = ILoanNotary.ContractParams({
            principal: _contractTerms.principal,
            contractTerms: _altPackedContractTerms, //*
            collateralAddress: address(_demoToken),
            collateralId: _collateralId,
            collateralNonce: _collateralNonce
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
            _contractParams,
            _borrowerSignature,
            _demoToken.ownerOf
        );

        // Create contract params with invalid nonce
        _contractParams = ILoanNotary.ContractParams({
            principal: _contractTerms.principal,
            contractTerms: _packedContractTerms,
            collateralAddress: address(_demoToken),
            collateralId: _collateralId,
            collateralNonce: _altCollateralNonce //*
        });

        // Verify and get borrower.
        vm.expectRevert(StdNotaryErrors.InvalidSigner.selector);
        _borrower = loanNotaryHarness.exposed__getBorrower(
            _collateralId,
            _contractParams,
            _borrowerSignature,
            _demoToken.ownerOf
        );
    }
}
