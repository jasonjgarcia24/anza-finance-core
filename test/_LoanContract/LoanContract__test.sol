// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdStyle} from "forge-std/StdStyle.sol";

import "@lending-constants/LoanContractRoles.sol";
import "@lending-constants/LoanContractStates.sol";
import {_SECONDS_PER_24_MINUTES_RATIO_SCALED_} from "@lending-constants/LoanContractNumbers.sol";
import {_INVALID_SIGNER_SELECTOR_} from "@custom-errors/StdNotaryErrors.sol";
import {_UINT64_MAX_, _UINT128_MAX_, _UINT256_MAX_, _SECP256K1_CURVE_ORDER_} from "@universal-numbers/StdNumbers.sol";

import {LoanContract} from "@base/LoanContract.sol";
import {LoanTreasurey} from "@base/services/LoanTreasurey.sol";
import {ILoanContract} from "@base/interfaces/ILoanContract.sol";
import {ILoanManager} from "@services/interfaces/ILoanManager.sol";
import {ILoanNotary, IRefinanceNotary} from "@services/interfaces/ILoanNotary.sol";
import {AnzaToken} from "@tokens/AnzaToken.sol";
import {CollateralVault} from "@services/CollateralVault.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";
import {TypeUtils} from "@base/libraries/TypeUtils.sol";

import "@test-databases/TestConstants__test.sol";
import {Setup} from "@test-base/Setup__test.sol";
import {LoanCodecHarness} from "@test-base/_LoanCodec/LoanCodec__test.sol";
import {LoanNotaryUtils} from "@test-base/_LoanNotary/LoanNotary__test.sol";
import {RefinanceNotaryUtils} from "@test-base/_LoanNotary/RefinanceNotary__test.sol";
import {SponsorshipNotaryUtils} from "@test-base/_LoanNotary/SponsorshipNotary__test.sol";
import {ILoanCodecHarness, LoanCodecUtils} from "@test-base/_LoanCodec/LoanCodec__test.sol";
import {DebtTermsInit, DebtTermsUtils} from "@test-databases/DebtTerms__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";
import {CONTRACT_INTIALIZED_EVENT_SIG} from "@test-base/_LoanContract/interfaces/ILoanContractEvents__test.sol";
import {BytesUtils} from "@test-utils/test-utils/BytesUtils.sol";
import {ERC1155EventsSuite} from "@test-utils/events/ERC1155EventsSuite__test.sol";
import {ERC721EventsSuite} from "@test-utils/events/ERC721EventsSuite__test.sol";
import {LoanContractEventsSuite} from "@test-utils/events/LoanContractEventsSuite__test.sol";
import {LoanCodecEventsSuite} from "@test-utils/events/LoanCodecEventsSuite__test.sol";
import {CollateralVaultEventsSuite} from "@test-utils/events/CollateralVaultEventsSuite__test.sol";
import {PaymentBookEventsSuite} from "@test-utils/events/PaymentBookEventsSuite__test.sol";

string constant LOAN_CONTRACT_NAME = "LoanContract";
string constant LOAN_CONTRACT_VERSION = "0";

contract LoanContractHarness is LoanContract {
    /* ----- LoanCodec Expose Functions ----- */
    function exposed__validateLoanTerms(
        bytes32 _contractTerms,
        uint64 _loanStart,
        uint256 _principal
    ) public pure {
        _validateLoanTerms(_contractTerms, _loanStart, _principal);
    }

    function exposed__getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) public pure returns (uint256) {
        return _getTotalFirIntervals(_firInterval, _seconds);
    }

    function exposed__setLoanAgreement(
        uint64 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) public {
        _setLoanAgreement(_now, _debtId, _activeLoanIndex, _contractTerms);
    }

    function exposed__updateLoanState(
        uint256 _debtId,
        uint8 _newLoanState
    ) public {
        _updateLoanState(_debtId, _newLoanState);
    }

    function exposed__updateLoanTimes(uint256 _debtId) public {
        _updateLoanTimes(_debtId);
    }

    /* Abstract functions */
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract LoanContractInit is DebtTermsInit {
    LoanContractHarness public loanContractHarness;
    LoanContractUtils public loanContractUtils;

    Notary.DomainSeparator internal _loanDomainSeparator;
    Notary.DomainSeparator internal _refinanceDomainSeparator;
    Notary.DomainSeparator internal _sponsorshipDomainSeparator;

    DemoToken internal _demoToken;

    function setUp() public virtual override {
        Setup.setUp();

        vm.startPrank(admin);

        // Deploy AnzaToken
        anzaToken = new AnzaToken("www.anza.io");

        // Deploy LoanContractHarness.
        loanContractHarness = new LoanContractHarness();

        // Deploy LoanTreasurey
        loanTreasurer = new LoanTreasurey();

        // Deploy CollateralVault
        collateralVault = new CollateralVault(address(anzaToken));

        // Set AnzaToken access control roles
        anzaToken.grantRole(_LOAN_CONTRACT_, address(loanContractHarness));
        anzaToken.grantRole(_TREASURER_, address(loanTreasurer));
        anzaToken.grantRole(_COLLATERAL_VAULT_, address(collateralVault));

        // Set LoanContract access control roles
        loanContractHarness.setAnzaToken(address(anzaToken));
        loanContractHarness.grantRole(_TREASURER_, address(loanTreasurer));
        loanContractHarness.setCollateralVault(address(collateralVault));

        // Set LoanContract access control roles
        loanContractHarness.setAnzaToken(address(anzaToken));
        loanContractHarness.setCollateralVault(address(collateralVault));

        // Set LoanTreasurey access control roles
        loanTreasurer.setAnzaToken(address(anzaToken));
        loanTreasurer.grantRole(_LOAN_CONTRACT_, address(loanContractHarness));
        loanTreasurer.grantRole(_COLLATERAL_VAULT_, address(collateralVault));

        // Set CollateralVault access control roles
        collateralVault.setLoanContract(address(loanContractHarness));
        collateralVault.grantRole(_TREASURER_, address(loanTreasurer));

        vm.stopPrank();

        // Deploy DemoToken with no token balance.
        _demoToken = new DemoToken(0);

        // Deploy LoanContractUtils.
        _loanDomainSeparator = Notary.DomainSeparator({
            name: LOAN_CONTRACT_NAME,
            version: LOAN_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(loanContractHarness)
        });

        _refinanceDomainSeparator = Notary.DomainSeparator({
            name: LOAN_CONTRACT_NAME,
            version: LOAN_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(loanContractHarness)
        });

        _sponsorshipDomainSeparator = Notary.DomainSeparator({
            name: LOAN_CONTRACT_NAME,
            version: LOAN_CONTRACT_VERSION,
            chainId: block.chainid,
            contractAddress: address(loanContractHarness)
        });

        loanContractUtils = new LoanContractUtils(
            address(loanContractHarness),
            address(loanTreasurer),
            address(anzaToken),
            address(_demoToken),
            _loanDomainSeparator,
            _refinanceDomainSeparator,
            _sponsorshipDomainSeparator
        );
    }
}

contract LoanContractUtils is
    LoanNotaryUtils,
    RefinanceNotaryUtils,
    SponsorshipNotaryUtils,
    LoanCodecUtils,
    DebtTermsUtils
{
    using TypeUtils for uint256;
    using BytesUtils for bytes[2];

    LoanContract internal immutable _loanContract;
    LoanTreasurey internal immutable _loanTreasurer;

    constructor(
        address _loanContractAddress,
        address _loanTreasurerAddress,
        address _anzaTokenAddress,
        address _demoTokenAddress_,
        Notary.DomainSeparator memory _loanDomainSeparator,
        Notary.DomainSeparator memory _refinanceDomainSeparator,
        Notary.DomainSeparator memory _sponsorshipDomainSeparator
    )
        LoanNotaryUtils(_demoTokenAddress_, _loanDomainSeparator)
        RefinanceNotaryUtils(
            _anzaTokenAddress,
            address(0) /* __anzaDebtMarket */,
            address(0) /* __anzaRefinanceStorefrontAddress */,
            _refinanceDomainSeparator
        )
        SponsorshipNotaryUtils(
            _anzaTokenAddress,
            address(0) /* __anzaDebtMarket */,
            address(0) /* __anzaSponsorshipStorefrontAddress */,
            _sponsorshipDomainSeparator
        )
    {
        _loanContract = LoanContract(_loanContractAddress);
        _loanTreasurer = LoanTreasurey(_loanTreasurerAddress);
    }

    /* -------- Initial Loan Contract Setup -------- */
    function initContract(
        uint256 _debtId,
        bytes32 _packedContractTerms,
        bytes memory _signature
    ) public virtual returns (bool _success, bytes memory _data) {
        // Create loan contract
        vm.startPrank(lender);
        (_success, _data) = address(_loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initContract(uint256,bytes32,bytes)",
                _debtId,
                _packedContractTerms,
                _signature
            )
        );

        vm.stopPrank();
    }

    function initContract(
        uint256 _debtId,
        uint256 _principal,
        bytes32 _packedContractTerms,
        bytes memory _signature
    ) public virtual returns (bool _success, bytes memory _data) {
        // Create loan contract
        vm.deal(lender, _principal + (1 ether));
        vm.startPrank(lender);
        (_success, _data) = address(_loanContract).call{value: _principal}(
            abi.encodeWithSignature(
                "initContract(uint256,bytes32,bytes)",
                _debtId,
                _packedContractTerms,
                _signature
            )
        );
        vm.stopPrank();
    }

    function initContract(
        uint256 _principal,
        address _collateralAddress,
        uint256 _collateralId,
        bytes32 _packedContractTerms,
        bytes memory _signature
    ) public virtual returns (bool _success, bytes memory _data) {
        // Create loan contract
        vm.deal(lender, _principal);
        vm.startPrank(lender);

        (_success, _data) = address(_loanContract).call{value: _principal}(
            abi.encodeWithSignature(
                "initContract(address,uint256,bytes32,bytes)",
                _collateralAddress,
                _collateralId,
                _packedContractTerms,
                _signature
            )
        );

        vm.stopPrank();
    }

    /**
     * Create a loan contract with default contract values.
     *
     * @param _borrowerPrivKey The borrower's private key.
     * @param _collateralId The collateral id.
     *
     * @return _success The success of the transaction.
     * @return _data The data returned from the transaction.
     */
    function createLoanContract(
        uint256 _borrowerPrivKey,
        address _collateralAddress,
        uint256 _collateralId
    )
        public
        virtual
        returns (
            bool _success,
            bytes memory _data,
            ContractTerms memory _contractTerms
        )
    {
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms();

        uint256 _collateralNonce = _loanContract.collateralNonce(
            _collateralAddress,
            _collateralId
        );

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _PRINCIPAL_,
                contractTerms: _packedContractTerms,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Create borrower's signature
        bytes memory _signature = createContractSignature(
            _borrowerPrivKey,
            _contractParams
        );

        // Create loan contract.
        (_success, _data) = initContract(
            _PRINCIPAL_,
            _collateralAddress,
            _collateralId,
            _packedContractTerms,
            _signature
        );
    }

    /**
     * Create a loan contract with contract values and the collateral specified.
     *
     * @param _borrowerPrivKey The borrower's private key.
     * @param _collateralAddress The collateral's address.
     * @param _collateralId The collateral's token ID.
     * @param _contractTerms The contract terms.
     */
    function createLoanContract(
        uint256 _borrowerPrivKey,
        address _collateralAddress,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public virtual returns (ContractTerms memory) {
        uint256 _collateralNonce = _loanContract.collateralNonce(
            _collateralAddress,
            _collateralId
        );

        // Create loan contract.
        return
            createLoanContract(
                _borrowerPrivKey,
                _collateralAddress,
                _collateralId,
                _collateralNonce,
                _contractTerms
            );
    }

    /**
     * Create a loan contract with the inputs specified.
     *
     * @param _borrowerPrivKey The borrower's private key.
     * @param _collateralAddress The collateral's address.
     * @param _collateralId The collateral's token ID.
     * @param _collateralNonce The collateral's nonce.
     * @param _contractTerms The contract terms.
     */
    function createLoanContract(
        uint256 _borrowerPrivKey,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _contractTerms
    ) public virtual returns (ContractTerms memory) {
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        // Create contract params.
        ILoanNotary.ContractParams memory _contractParams = ILoanNotary
            .ContractParams({
                principal: _contractTerms.principal,
                contractTerms: _packedContractTerms,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            });

        // Create borrower's signature
        bytes memory _signature = createContractSignature(
            _borrowerPrivKey,
            _contractParams
        );

        // Create loan contract.
        (bool _success, bytes memory _data) = initContract(
            _contractTerms.principal,
            _contractParams.collateralAddress,
            _contractParams.collateralId,
            _contractParams.contractTerms,
            _signature
        );

        handleFailedContractCreation(_success, _data, _contractTerms);

        return _contractTerms;
    }

    /* ------- Refinance Loan Contract Setup ------- */
    function refinanceContract(
        uint256 _principal,
        address _borrower,
        address _lender,
        uint256 _debtId,
        bytes32 _packedContractTerms
    ) public virtual returns (bool _success, bytes memory _data) {
        // Create loan contract
        vm.deal(address(_loanTreasurer), _principal);
        vm.startPrank(address(_loanTreasurer));

        (_success, _data) = address(_loanContract).call{value: _principal}(
            abi.encodeWithSignature(
                "initContract(uint256,address,address,bytes32)",
                _debtId,
                _borrower,
                _lender,
                _packedContractTerms
            )
        );

        vm.stopPrank();
    }

    /**
     * Refinance a loan contract with the inputs specified.
     *
     * @param _borrower The borrower's address.
     * @param _lender The lender's address.
     * @param _debtId The debt ID.
     * @param _contractTerms The contract terms.
     */
    function refinanceLoanContract(
        address _borrower,
        address _lender,
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public virtual {
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        // Create loan contract.
        (bool _success, bytes memory _data) = refinanceContract(
            _contractTerms.principal,
            _borrower,
            _lender,
            _debtId,
            _packedContractTerms
        );

        handleFailedContractCreation(_success, _data, _contractTerms);
    }

    /* ------- Sponsorship Loan Contract Setup ------- */
    function sponsorshipContract(
        uint256 _principal,
        address _borrower,
        address _lender,
        uint256 _debtId
    ) public virtual returns (bool _success, bytes memory _data) {
        // Create loan contract
        vm.deal(address(_loanTreasurer), _principal);
        vm.startPrank(address(_loanTreasurer));

        (_success, _data) = address(_loanContract).call{value: _principal}(
            abi.encodeWithSignature(
                "initContract(uint256,address,address)",
                _debtId,
                _borrower,
                _lender
            )
        );

        vm.stopPrank();
    }

    /**
     * Sponsorship a loan contract with the inputs specified.
     *
     * @param _borrower The borrower's address.
     * @param _lender The lender's address.
     * @param _debtId The debt ID.
     * @param _contractTerms The contract terms.
     */
    function sponsorshipLoanContract(
        address _borrower,
        address _lender,
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public virtual {
        // Create loan contract.
        (bool _success, bytes memory _data) = sponsorshipContract(
            _contractTerms.principal,
            _borrower,
            _lender,
            _debtId
        );

        handleFailedContractCreation(_success, _data, _contractTerms);
    }

    /**
     * Function to handle failed contract creations.
     *
     * @dev If a contract's creation failed, this function will check the expected
     * faiulure versus the actual failure to ensure the failure was expected.
     *
     * @param _success The success of the contract creation.
     * @param _data The error message of the contract creation.
     * @param _contractTerms The contract terms.
     */
    function handleFailedContractCreation(
        bool _success,
        bytes memory _data,
        ContractTerms memory _contractTerms
    ) public {
        if (_success) return;

        // Set contract initialization expectation.
        (
            bool _expectedSuccess,
            bytes memory _expectedData
        ) = expectedContractTermsValidity(
                _contractTerms,
                address(_loanContract),
                uint64(block.timestamp)
            );

        // Get expected return data.
        (_expectedData, _data) = [_expectedData, _data].normalizeBytesMSB();

        assertEq(
            _expectedSuccess,
            _success,
            "0 :: init loan contract expected failure."
        );
        assertEq(
            _expectedData,
            _data,
            "1 :: init loan contract error message mismatch."
        );

        // Force rerun.
        vm.assume(_success);
    }
}

contract LoanContractUnitTest is
    LoanContractInit,
    ERC1155EventsSuite,
    ERC721EventsSuite,
    LoanContractEventsSuite,
    LoanCodecEventsSuite,
    CollateralVaultEventsSuite,
    PaymentBookEventsSuite
{
    using BytesUtils for bytes[2];
    using AnzaTokenIndexer for uint256;

    uint256 public localCollateralId = collateralId;

    function setUp() public virtual override {
        super.setUp();
    }

    /**
     * Test the init contract function.
     *
     * @notice This test conducts testing on the loan contract initialization
     * of a new initial loan (i.e. leveraging the borrower's collateral).
     *
     * @notice Test Function:
     *  initContract(
     *      address _collateralAddress,
     *      uint256 _collateralId,
     *      bytes32 _contractTerms,
     *      bytes calldata _borrowerSignature
     *  )
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _contractTerms The contract terms.
     */
    function _testLoanContract__InitContract_Fuzz_InitialLoan(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public returns (uint256, ContractTerms memory) {
        uint256 _debtId;

        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );

        _contractTerms = loanContractUtils.cleanContractTerms(
            ILoanCodecHarness(address(loanContractHarness)),
            _contractTerms
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Mint collateral and approve loan contract.
        _demoToken.exposed__mint(_borrower, _collateralId);

        vm.startPrank(_borrower);
        _demoToken.approve(address(loanContractHarness), _collateralId);
        vm.stopPrank();

        // Get collateral nonce.
        uint256 _collateralNonce = loanContractHarness.collateralNonce(
            address(_demoToken),
            _collateralId
        );

        // Create loan contract.
        vm.recordLogs();
        _contractTerms = loanContractUtils.createLoanContract(
            _borrowerPrivKey,
            address(_demoToken),
            _collateralId,
            _collateralNonce,
            _contractTerms
        );

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        // Verify successful contract creation results.
        (_debtId, ) = loanContractHarness.collateralDebtAt(
            address(_demoToken),
            _collateralId,
            type(uint256).max
        );

        // Transfer event for collateral into CollateralVault.
        _testTransfer(
            _entries[0],
            TransferFields({
                from: _borrower,
                to: address(collateralVault),
                tokenId: _collateralId
            })
        );

        // Ignore DemoToken convenience approval event.
        // _entries[1]

        // DepositedCollateral event for collateral into CollateralVault.
        _testDepositedCollateral(
            _entries[2],
            DepositedCollateralFields({
                from: _borrower,
                collateralAddress: address(_demoToken),
                collateralId: _collateralId
            })
        );

        // Deposited event for funds into LoanTreasurer.
        _testDeposited(
            _entries[3],
            DepositedFields({
                debtId: _debtId,
                payer: lender,
                payee: _borrower,
                weiAmount: _contractTerms.principal
            })
        );

        // TransferSingle event for lender token mints.
        _testTransferSingle(
            _entries[4],
            TransferSingleFields({
                operator: address(loanContractHarness),
                from: address(0),
                to: lender,
                id: _debtId.debtIdToLenderTokenId(),
                value: _contractTerms.principal
            })
        );

        // TransferSingle event for borrower token mints.
        _testTransferSingle(
            _entries[5],
            TransferSingleFields({
                operator: address(loanContractHarness),
                from: address(0),
                to: _borrower,
                id: _debtId.debtIdToBorrowerTokenId(),
                value: 1
            })
        );

        // URI event for setting borrower token URI.
        _testURI(
            _entries[6],
            URIFields({
                value: _demoToken.tokenURI(_collateralId),
                id: _debtId.debtIdToBorrowerTokenId()
            })
        );

        // ContractInitialized event.
        _testContractInitialized(
            _entries[7],
            ContractInitializedFields({
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                debtId: _debtId,
                activeLoanIndex: 1
            })
        );

        return (_debtId, _contractTerms);
    }

    /**
     * Test the contract refinancing function.
     *
     * @notice This test conducts testing on the loan contract refinancing
     * into a new loan.
     *
     * @notice Test Function:
     *  initContract(
     *      uint256 _debtId,
     *      address _borrower,
     *      address _lender,
     *      bytes32 _contractTerms
     *  )
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _lender The address of the lender.
     * @param _collateralId The id of the collateral.
     * @param _contractTerms The contract terms.
     */
    function _testLoanContract__InitContract_Fuzz_RefinanceLoan(
        uint256 _borrowerPrivKey,
        address _lender,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public returns (uint256, ContractTerms memory) {
        uint256 _debtId;

        // Limit principal for vm.deal limitations.
        _contractTerms.principal = bound(
            _contractTerms.principal,
            1,
            _UINT128_MAX_
        );

        (
            _debtId,
            _contractTerms
        ) = _testLoanContract__InitContract_Fuzz_InitialLoan(
            _borrowerPrivKey,
            _collateralId,
            _contractTerms
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Create loan contract.
        vm.recordLogs();
        loanContractUtils.refinanceLoanContract(
            _borrower,
            _lender,
            _debtId,
            _contractTerms
        );

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        uint256 _prevDebtId = _debtId;

        (_debtId, ) = loanContractHarness.collateralDebtAt(
            address(_demoToken),
            _collateralId,
            type(uint256).max
        );

        // Test updated debt ID.
        assertEq(
            _prevDebtId + 1,
            _debtId,
            "1 :: debt id should increment by 1."
        );

        // TransferSingle event for lender token mints.
        _testTransferSingle(
            _entries[0],
            TransferSingleFields({
                operator: address(loanTreasurer),
                from: lender,
                to: address(0),
                id: _prevDebtId.debtIdToLenderTokenId(),
                value: _contractTerms.principal
            })
        );

        // Deposited event for funds into LoanTreasurer.
        _testDeposited(
            _entries[1],
            DepositedFields({
                debtId: _prevDebtId,
                payer: _lender,
                payee: lender,
                weiAmount: _contractTerms.principal
            })
        );

        // LoanStateChanged event for prev debt ID payoff.
        _testLoanStateChanged(
            _entries[2],
            LoanStateChangedFields({
                debtId: _prevDebtId,
                newLoanState: _PAID_STATE_,
                oldLoanState: _contractTerms.gracePeriod == 0
                    ? _ACTIVE_STATE_
                    : _ACTIVE_GRACE_STATE_
            })
        );

        // TransferSingle event for lender token mints.
        _testTransferSingle(
            _entries[3],
            TransferSingleFields({
                operator: address(loanContractHarness),
                from: address(0),
                to: _lender,
                id: _debtId.debtIdToLenderTokenId(),
                value: _contractTerms.principal
            })
        );

        // TransferSingle event for borrower token mints.
        _testTransferSingle(
            _entries[4],
            TransferSingleFields({
                operator: address(loanContractHarness),
                from: address(0),
                to: _borrower,
                id: _debtId.debtIdToBorrowerTokenId(),
                value: 1
            })
        );

        // URI event for setting borrower token URI.
        _testURI(
            _entries[5],
            URIFields({
                value: _demoToken.tokenURI(_collateralId),
                id: _debtId.debtIdToBorrowerTokenId()
            })
        );

        // ContractInitialized event.
        _testContractInitialized(
            _entries[6],
            ContractInitializedFields({
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                debtId: _debtId,
                activeLoanIndex: 2
            })
        );

        return (_debtId, _contractTerms);
    }

    /**
     * Test the contract sponsoring function.
     *
     * @notice This test conducts testing on the loan contract refinancing
     * into a new loan.
     *
     * @notice Test Function:
     *  initContract(
     *      uint256 _debtId,
     *      address _borrower,
     *      address _lender,
     *      bytes32 _contractTerms
     *  )
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _lender The address of the lender.
     * @param _collateralId The id of the collateral.
     * @param _contractTerms The contract terms.
     */
    function _testLoanContract__InitContract_Fuzz_SponshorshipLoan(
        uint256 _borrowerPrivKey,
        address _lender,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public returns (uint256, ContractTerms memory) {
        uint256 _debtId;

        (
            _debtId,
            _contractTerms
        ) = _testLoanContract__InitContract_Fuzz_InitialLoan(
            _borrowerPrivKey,
            _collateralId,
            _contractTerms
        );

        address _borrower = vm.addr(_borrowerPrivKey);

        // Create loan contract.
        vm.recordLogs();
        loanContractUtils.sponsorshipLoanContract(
            _borrower,
            _lender,
            _debtId,
            _contractTerms
        );

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        // if (_success) {
        (_debtId, ) = loanContractHarness.collateralDebtAt(
            address(_demoToken),
            _collateralId,
            _UINT256_MAX_
        );

        // TransferSingle event for lender token mints.
        _testTransferSingle(
            _entries[0],
            TransferSingleFields({
                operator: address(loanTreasurer),
                from: lender,
                to: address(0),
                id: (_debtId - 1).debtIdToLenderTokenId(),
                value: _contractTerms.principal
            })
        );

        // Deposited event for funds into LoanTreasurer.
        _testDeposited(
            _entries[1],
            DepositedFields({
                debtId: _debtId - 1,
                payer: _lender,
                payee: lender,
                weiAmount: _contractTerms.principal
            })
        );

        // LoanStateChanged event for prev debt ID payoff.
        _testLoanStateChanged(
            _entries[2],
            LoanStateChangedFields({
                debtId: _debtId - 1,
                newLoanState: _PAID_STATE_,
                oldLoanState: _contractTerms.gracePeriod == 0
                    ? _ACTIVE_STATE_
                    : _ACTIVE_GRACE_STATE_
            })
        );

        // TransferSingle event for lender token mints.
        _testTransferSingle(
            _entries[3],
            TransferSingleFields({
                operator: address(loanContractHarness),
                from: address(0),
                to: _lender,
                id: _debtId.debtIdToLenderTokenId(),
                value: _contractTerms.principal
            })
        );

        // TransferSingle event for borrower token mints.
        _testTransferSingle(
            _entries[4],
            TransferSingleFields({
                operator: address(loanContractHarness),
                from: address(0),
                to: _borrower,
                id: _debtId.debtIdToBorrowerTokenId(),
                value: 1
            })
        );

        // URI event for setting borrower token URI.
        _testURI(
            _entries[5],
            URIFields({
                value: _demoToken.tokenURI(_collateralId),
                id: _debtId.debtIdToBorrowerTokenId()
            })
        );

        // ContractInitialized event.
        _testContractInitialized(
            _entries[6],
            ContractInitializedFields({
                collateralAddress: address(_demoToken),
                collateralId: _collateralId,
                debtId: _debtId,
                activeLoanIndex: 2
            })
        );

        return (_debtId, _contractTerms);
    }

    /* --------------- LoanContract.initContract() --------------- */
    /**
     * See {_testLoanContract__InitContract_Fuzz_InitialLoan}.
     */
    function testLoanContract__InitContract_Fuzz_InitialLoan(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public {
        uint256 _debtId;
        uint64 _now = uint64(block.timestamp);

        (
            _debtId,
            _contractTerms
        ) = _testLoanContract__InitContract_Fuzz_InitialLoan(
            _borrowerPrivKey,
            _collateralId,
            _contractTerms
        );

        // Check the unpacked contract terms.
        loanContractUtils.checkLoanTerms(
            address(loanContractHarness),
            _debtId,
            1,
            _now,
            _contractTerms
        );
    }

    /* --------------- LoanContract.initContract() --------------- */
    /**
     * See {_testLoanContract__InitContract_Fuzz_RefinanceLoan}.
     */
    function testLoanContract__InitContract_Fuzz_RefinanceLoan(
        uint256 _borrowerPrivKey,
        address _lender,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public {
        uint256 _debtId;

        vm.assume(_lender != address(0));
        uint64 _now = uint64(block.timestamp);

        (
            _debtId,
            _contractTerms
        ) = _testLoanContract__InitContract_Fuzz_RefinanceLoan(
            _borrowerPrivKey,
            _lender,
            _collateralId,
            _contractTerms
        );

        // Check the unpacked contract terms.
        loanContractUtils.checkLoanTerms(
            address(loanContractHarness),
            _debtId,
            2,
            _now,
            _contractTerms
        );
    }

    /* --------------- LoanContract.initContract() --------------- */
    /**
     * See {_testLoanContract__InitContract_Fuzz_SponshorshipLoan}.
     */
    function testLoanContract__InitContract_Fuzz_SponshorshipLoan(
        uint256 _borrowerPrivKey,
        address _lender,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public {
        uint256 _debtId;

        vm.assume(_lender != address(0));
        uint64 _now = uint64(block.timestamp);

        (
            _debtId,
            _contractTerms
        ) = _testLoanContract__InitContract_Fuzz_SponshorshipLoan(
            _borrowerPrivKey,
            _lender,
            _collateralId,
            _contractTerms
        );

        // Check the unpacked contract terms.
        loanContractUtils.checkLoanTerms(
            address(loanContractHarness),
            _debtId,
            2,
            _now,
            _contractTerms
        );
    }

    /* -------------- LoanContract.revokeProposal() ------------- */
    /**
     * Test the init contract function.
     *
     * @notice This test conducts testing on the loan contract initialization
     * of a new initial loan (i.e. leveraging the borrower's collateral).
     *
     * @notice Test Function:
     *  initContract(
     *      address _collateralAddress,
     *      uint256 _collateralId,
     *      bytes32 _contractTerms,
     *      bytes calldata _borrowerSignature
     *  )
     *
     * @param _borrowerPrivKey The private key of the borrower.
     * @param _collateralId The id of the collateral.
     * @param _contractTerms The contract terms.
     */
    function testLoanContract__RevokeProposal_Fuzz(
        uint256 _borrowerPrivKey,
        uint256 _collateralId,
        ContractTerms memory _contractTerms
    ) public {
        vm.assume(
            _borrowerPrivKey != 0 && _borrowerPrivKey < _SECP256K1_CURVE_ORDER_
        );

        _contractTerms = loanContractUtils.cleanContractTerms(
            ILoanCodecHarness(address(loanContractHarness)),
            _contractTerms
        );

        address _borrower = vm.addr(_borrowerPrivKey);
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );

        // Get collateral nonce.
        uint256 _collateralNonce = loanContractHarness.collateralNonce(
            address(_demoToken),
            _collateralId
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

        // Create borrower's signature
        bytes memory _signature = loanContractUtils.createContractSignature(
            _borrowerPrivKey,
            _contractParams
        );

        // Mint collateral and approve loan contract.
        _demoToken.exposed__mint(_borrower, _collateralId);

        vm.startPrank(_borrower);
        loanContractHarness.revokeProposal(
            address(_demoToken),
            _collateralId,
            _contractTerms.principal,
            _packedContractTerms,
            _signature
        );
        vm.stopPrank();

        // Collateral nonce should have been incremented by 1.
        assertEq(
            loanContractHarness.collateralNonce(
                address(_demoToken),
                _collateralId
            ),
            _collateralNonce + 1,
            "0 :: collateral nonce mismatch."
        );

        // FAIL :: Create loan contract
        vm.deal(lender, _contractTerms.principal);
        vm.startPrank(lender);
        (bool _success, bytes memory _data) = address(loanContractHarness).call{
            value: _contractTerms.principal
        }(
            abi.encodeWithSignature(
                "initContract(address,uint256,bytes32,bytes)",
                address(_demoToken),
                _collateralId,
                _packedContractTerms,
                _signature
            )
        );
        vm.stopPrank();

        assertFalse(_success, "1 :: initContract should fail.");
        assertEq(
            bytes4(_data),
            _INVALID_SIGNER_SELECTOR_,
            "2 :: invalid signer failure expected."
        );
    }
}
