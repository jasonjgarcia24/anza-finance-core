// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import "@lending-constants/LoanContractStates.sol";
import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";

import {AnzaDebtExchange} from "@markets/AnzaDebtExchange.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {LoanContractHarness} from "@test-base/_LoanContract/LoanContract__test.sol";
import {ILoanCodecHarness, LoanCodecUtils} from "@test-base/_LoanCodec/LoanCodec__test.sol";

contract AnzaDebtExchangeHarness is AnzaDebtExchange {
    function exposed__executeDebtExchange(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _beneficiary,
        uint256 _payment
    ) public returns (bool _results) {
        return
            _executeDebtExchange(
                _collateralAddress,
                _collateralId,
                _borrower,
                _beneficiary,
                _payment
            );
    }

    function exposed_depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) public returns (uint256) {
        return _depositPayment(_payer, _debtId, _payment);
    }
}

abstract contract AnzaDebtExchangeInit is Setup {
    AnzaDebtExchangeHarness public anzaDebtExchangeHarness;
    AnzaTokenHarness public anzaTokenHarness;
    LoanContractHarness public loanContractHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();

        // Deploy LoanContractHarness.
        loanContractHarness = new LoanContractHarness();

        // Deploy AnzaDebtExchange
        anzaDebtExchangeHarness = new AnzaDebtExchangeHarness();

        // Set AnzaToken access control roles
        anzaTokenHarness.grantRole(
            _LOAN_CONTRACT_,
            address(loanContractHarness)
        );
        anzaTokenHarness.grantRole(
            _TREASURER_,
            address(anzaDebtExchangeHarness)
        );

        // Set LoanContract access control roles
        loanContractHarness.setAnzaToken(address(anzaTokenHarness));
        loanContractHarness.grantRole(
            _TREASURER_,
            address(anzaDebtExchangeHarness)
        );

        // Set LoanTreasurey access control roles
        anzaDebtExchangeHarness.setAnzaToken(address(anzaTokenHarness));
        anzaDebtExchangeHarness.grantRole(
            _LOAN_CONTRACT_,
            address(loanContractHarness)
        );

        vm.stopPrank();
    }
}

contract AnzaDebtExchangeUtils is LoanCodecUtils {}

contract AnzaDebtExchangeUnitTest is AnzaDebtExchangeInit {
    using AnzaTokenIndexer for uint256;

    AnzaDebtExchangeUtils public anzaDebtExchangeUtils;

    struct Debt {
        uint256 debt_id;
        bytes32 debt_terms;
    }

    struct Terms {
        uint256 commital_period;
        uint256 commital_ratio;
        uint256 duration;
        uint256 fir_interval;
        uint256 fixed_interest_rate;
        uint256 grace_period;
        uint256 is_fixed;
        uint256 lender_royalties;
        uint256 principal;
        uint256 terms_expiry;
    }

    struct ReportData {
        Debt debt;
        Terms contractTerms;
    }

    function setUp() public virtual override {
        super.setUp();

        // Deploy AnzaDebtExchangeUtils
        anzaDebtExchangeUtils = new AnzaDebtExchangeUtils();
    }

    /* -------- AnzaDebtExchange.setAnzaToken() --------- */
    /**
     * Fuzz test the set AnzaToken address function.
     *
     * @param _anzaTokenAddress The address of the AnzaToken contract.
     *
     * @dev Full pass if the AnzaToken address is set as expected.
     */
    function testAnzaDebtExchange_SetAnzaToken_Fuzz(
        address _anzaTokenAddress
    ) public {
        assertEq(
            anzaDebtExchangeHarness.anzaToken(),
            address(0),
            "0 :: anzaTokenAddress should be address(0)"
        );

        vm.expectRevert(
            abi.encodePacked(getAccessControlFailMsg(_ADMIN_, address(this)))
        );
        anzaDebtExchangeHarness.setAnzaToken(_anzaTokenAddress);

        vm.startPrank(admin);
        anzaDebtExchangeHarness.setAnzaToken(_anzaTokenAddress);
        vm.stopPrank();

        assertEq(
            anzaDebtExchangeHarness.anzaToken(),
            _anzaTokenAddress,
            "1 :: anzaTokenAddress should be _anzaTokenAddress"
        );

        vm.startPrank(admin);
        anzaDebtExchangeHarness.setAnzaToken(address(0));
        vm.stopPrank();

        assertEq(
            anzaDebtExchangeHarness.anzaToken(),
            address(0),
            "2 :: anzaTokenAddress should be address(0)"
        );
    }

    /* ---- AnzaDebtExchange._executeDebtExchange() ----- */
    /**
     * Fuzz test the internal execute debt exchange function.
     *
     * @param _collateralId The id of the collateral token.
     * @param _borrower The address of the borrower.
     * @param _purchaser The address of the purchaser.
     * @param _amount The amount of collateral to be exchanged.
     * @param _payment The amount of payment to be exchanged.
     * @param _debtId The id of the debt token.
     *
     * @dev Full pass if the debt exchange is executed as expected.
     */
    function testAnzaDebtExchange__ExecuteDebtExchange_Fuzz(
        uint256 _collateralId,
        address _borrower,
        address _purchaser,
        uint256 _amount,
        uint256 _payment,
        uint256 _debtId
    ) public {
        vm.assume(_borrower != address(0) && _purchaser != address(0));
        vm.assume(_amount != 0);
        vm.assume(_debtId <= _MAX_DEBT_ID_);

        DemoToken _demoToken = new DemoToken(0);

        // Mint collateral and approve loan contract.
        _demoToken.exposed__mint(_borrower, _collateralId);

        // AnzaToken mint.
        anzaTokenHarness.exposed__mint(
            _borrower,
            _debtId.debtIdToBorrowerTokenId(),
            1
        );
        anzaTokenHarness.exposed__mint(
            _borrower,
            _debtId.debtIdToLenderTokenId(),
            _amount
        );

        // Access control denial
        vm.startPrank(admin);
        anzaTokenHarness.revokeRole(
            _TREASURER_,
            address(anzaDebtExchangeHarness)
        );
        vm.stopPrank();

        vm.expectRevert(
            abi.encodePacked(
                getAccessControlFailMsg(
                    _TREASURER_,
                    address(anzaDebtExchangeHarness)
                )
            )
        );
        bool _success = anzaDebtExchangeHarness.exposed__executeDebtExchange(
            address(_demoToken),
            _collateralId,
            _borrower,
            _purchaser,
            _payment
        );

        // Access control allowed
        vm.startPrank(admin);
        anzaTokenHarness.grantRole(
            _TREASURER_,
            address(anzaDebtExchangeHarness)
        );
        vm.stopPrank();

        _success = anzaDebtExchangeHarness.exposed__executeDebtExchange(
            address(_demoToken),
            _collateralId,
            _borrower,
            _purchaser,
            _payment
        );
    }

    /* ------ AnzaDebtExchange._depositPayment() ------- */
    function testAnzaDebtExchange__depositPayment(
        ContractTerms memory _contractTerms,
        uint256 _debtId
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_ && _debtId != 0);

        _contractTerms = anzaDebtExchangeUtils.cleanContractTerms(
            ILoanCodecHarness(address(loanContractHarness)),
            _contractTerms
        );

        uint64 _now = uint64(block.timestamp);
        uint256 _activeLoanIndex = 1;

        // Pack and store the contract terms.
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );
        vm.assume(_packedContractTerms != bytes32(0));

        loanContractHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        recordDebtData(
            "testAnzaDebtExchange__ExecuteDebtExchange_Fuzz",
            Debt({debt_id: _debtId, debt_terms: _packedContractTerms}),
            _contractTerms
        );
    }

    function recordDebtData(
        string memory _outputFile,
        Debt memory _debt,
        ContractTerms memory _contractTerms
    ) public {
        _outputFile = string(
            abi.encodePacked("./output/", _outputFile, ".json")
        );

        // Read data.
        bytes memory _inputData = readJson(_outputFile);

        // Parse data.
        string memory _outputData = parseJson(
            _inputData,
            _debt,
            _contractTerms
        );

        // Write data.
        vm.writeJson(_outputData, _outputFile);
    }

    function readJson(
        string memory _file
    ) public view returns (bytes memory _fileData) {
        try vm.readFile(_file) returns (string memory _fileStr) {
            _fileData = bytes(_fileStr).length > 0
                ? vm.parseJson(_fileStr)
                : new bytes(0);
        } catch (bytes memory) {
            _fileData = new bytes(0);
        }
    }

    function parseJson(
        bytes memory _prevDebt,
        Debt memory _newDebt,
        ContractTerms memory _contractTerms
    ) public returns (string memory _outputData) {
        // Collect all debt data.
        uint256 _debtDataLength = 32 * 12;
        uint256 _numElements = _prevDebt.length / _debtDataLength;
        bytes memory _chunk = new bytes(_debtDataLength);

        string memory _debtMapObjKey = "debt_maps";
        for (uint256 i; i <= _numElements; i++) {
            ReportData memory _reportData;
            string memory _debtValueKey = "debt_map_";

            // Get previous run's data.
            if (i < _numElements) {
                uint256 _offset = i * _debtDataLength;

                for (uint256 j; j < _debtDataLength; j++)
                    _chunk[j] = _prevDebt[_offset + j];

                _reportData = abi.decode(_chunk, (ReportData));
            }
            // Get new run's data.
            else {
                _reportData.debt = _newDebt;
                _reportData.contractTerms = Terms({
                    commital_period: uint256(_contractTerms.commitalPeriod),
                    commital_ratio: uint256(_contractTerms.commitalRatio),
                    duration: uint256(_contractTerms.duration),
                    fir_interval: uint256(_contractTerms.firInterval),
                    fixed_interest_rate: uint256(
                        _contractTerms.fixedInterestRate
                    ),
                    grace_period: uint256(_contractTerms.gracePeriod),
                    is_fixed: uint256(_contractTerms.isFixed),
                    lender_royalties: uint256(_contractTerms.lenderRoyalties),
                    principal: uint256(_contractTerms.principal),
                    terms_expiry: uint256(_contractTerms.termsExpiry)
                });
            }

            // Set unique key for this debt test run.
            _debtValueKey = string(
                abi.encodePacked(_debtValueKey, vm.toString(i))
            );

            // Package Debt object.
            vm.serializeUint(
                _debtValueKey,
                "debt_id",
                _reportData.debt.debt_id
            );
            string memory _debtObj = vm.serializeBytes32(
                _debtValueKey,
                "debt_terms",
                _reportData.debt.debt_terms
            );

            // Package ContractTerms object.
            vm.serializeUint(
                "terms",
                "fir_interval",
                _reportData.contractTerms.fir_interval
            );
            vm.serializeUint(
                "terms",
                "fixed_interest_rate",
                _reportData.contractTerms.fixed_interest_rate
            );
            vm.serializeUint(
                "terms",
                "is_fixed",
                _reportData.contractTerms.is_fixed
            );
            vm.serializeUint(
                "terms",
                "commital_ratio",
                _reportData.contractTerms.commital_ratio
            );
            vm.serializeUint(
                "terms",
                "commital_period",
                _reportData.contractTerms.commital_period
            );
            vm.serializeUint(
                "terms",
                "principal",
                _reportData.contractTerms.principal
            );
            vm.serializeUint(
                "terms",
                "grace_period",
                _reportData.contractTerms.grace_period
            );
            vm.serializeUint(
                "terms",
                "duration",
                _reportData.contractTerms.duration
            );
            vm.serializeUint(
                "terms",
                "terms_expiry",
                _reportData.contractTerms.terms_expiry
            );
            string memory _termsObj = vm.serializeUint(
                "terms",
                "lender_royalties",
                _reportData.contractTerms.lender_royalties
            );

            // Package debtObj within appended group of objects.
            vm.serializeString(_debtMapObjKey, "terms", _termsObj);

            string memory _bundledObj = vm.serializeString(
                _debtMapObjKey,
                "debt_terms",
                _debtObj
            );

            _outputData = vm.serializeString(
                "output_data",
                _debtValueKey,
                _bundledObj
            );
        }
    }
}
