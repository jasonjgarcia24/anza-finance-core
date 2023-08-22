// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdStyle} from "forge-std/StdStyle.sol";

import "@lending-constants/LoanContractStates.sol";
import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_EXPIRED_LOAN_SELECTOR_} from "@custom-errors/StdCodecErrors.sol";

import {AnzaDebtExchange} from "@markets/AnzaDebtExchange.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";
import {IPaymentBook} from "@lending-databases/interfaces/IPaymentBook.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {LoanContractHarness} from "@test-base/_LoanContract/LoanContract__test.sol";
import {ILoanCodecHarness, LoanCodecUtils} from "@test-base/_LoanCodec/LoanCodec__test.sol";
import {LoanCodecEventsSuite} from "@test-utils/events/LoanCodecEventsSuite__test.sol";
import {IPaymentBookEvents, PaymentBookEventsSuite} from "@test-utils/events/PaymentBookEventsSuite__test.sol";
import {ERC1155EventsSuite} from "@test-utils/events/ERC1155EventsSuite__test.sol";

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

    function exposed__depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) public returns (uint256) {
        return _depositPayment(_payer, _debtId, _payment);
    }

    function exposed__depositPayment_updatePermitted(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) public debtUpdater(_debtId) returns (uint256 _remainingPayment) {
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

contract AnzaDebtExchangeUnitTest is
    AnzaDebtExchangeInit,
    LoanCodecEventsSuite,
    PaymentBookEventsSuite,
    ERC1155EventsSuite
{
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

    function _debtSetup(
        ContractTerms memory _contractTerms,
        uint256 _collateralId,
        address _borrower,
        uint256 _debtId
    )
        internal
        returns (
            address _lender,
            address _demoTokenAddress,
            uint256 _oldLoanState
        )
    {
        _lender = makeAddr("LENDER");

        _contractTerms = anzaDebtExchangeUtils.cleanContractTerms(
            ILoanCodecHarness(address(loanContractHarness)),
            _contractTerms
        );

        // Pack and store the contract terms.
        bytes32 _packedContractTerms;
        (_packedContractTerms, _contractTerms) = createPackedContractTerms(
            _contractTerms
        );
        vm.assume(_packedContractTerms != bytes32(0));

        loanContractHarness.exposed__setLoanAgreement(
            uint64(block.timestamp),
            _debtId,
            0,
            _packedContractTerms
        );
        _oldLoanState = loanContractHarness.loanState(_debtId);

        // Mint collateral and approve loan contract.
        DemoToken _demoToken = new DemoToken(0);
        _demoTokenAddress = address(_demoToken);
        _demoToken.exposed__mint(_borrower, _collateralId);

        // AnzaToken mint.
        anzaTokenHarness.exposed__mint(
            _borrower,
            _debtId.debtIdToBorrowerTokenId(),
            1
        );
        anzaTokenHarness.exposed__mint(
            _lender,
            _debtId.debtIdToLenderTokenId(),
            _contractTerms.principal
        );

        // Write debt to database.
        loanContractHarness.exposed__writeDebt(
            address(_demoToken),
            _collateralId,
            _debtId
        );

        assertEq(
            anzaTokenHarness.borrowerOf(_debtId),
            _borrower,
            "0 :: _debtSetup :: borrower should be _borrower"
        );
        assertEq(
            anzaTokenHarness.lenderOf(_debtId),
            _lender,
            "1 :: _debtSetup :: lender should be _lender"
        );
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
        address _alt_account = makeAddr("ALT_ACCOUNT");
        vm.startPrank(_alt_account);
        vm.expectRevert(
            abi.encodePacked(getAccessControlFailMsg(_ADMIN_, _alt_account))
        );
        anzaDebtExchangeHarness.setAnzaToken(_anzaTokenAddress);
        vm.stopPrank();

        vm.startPrank(admin);
        anzaDebtExchangeHarness.setAnzaToken(_anzaTokenAddress);

        assertEq(
            anzaDebtExchangeHarness.anzaToken(),
            _anzaTokenAddress,
            "0 :: anzaTokenAddress should be _anzaTokenAddress"
        );

        anzaDebtExchangeHarness.setAnzaToken(address(0));

        assertEq(
            anzaDebtExchangeHarness.anzaToken(),
            address(0),
            "1 :: anzaTokenAddress should be address(0)"
        );
        vm.stopPrank();
    }

    /* ---- AnzaDebtExchange._executeDebtExchange() ----- */
    /**
     * Fuzz test the internal execute debt exchange function.
     *
     * @param _collateralId The id of the collateral token.
     * @param _borrower The address of the borrower.
     * @param _purchaser The address of the purchaser.
     * @param _payment The amount of payment to be exchanged.
     * @param _debtId The id of the debt token.
     *
     * @dev Full pass if the debt exchange is executed as expected.
     */
    function testAnzaDebtExchange__ExecuteDebtExchange_Fuzz(
        ContractTerms memory _contractTerms,
        uint256 _collateralId,
        address _borrower,
        address _purchaser,
        uint256 _payment,
        uint256 _debtId
    ) public {
        vm.assume(_borrower != address(0) && _borrower.code.length == 0);
        vm.assume(_purchaser != address(0) && _purchaser.code.length == 0);
        vm.assume(_borrower != _purchaser);
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        vm.label(_borrower, "BORROWER");
        vm.label(_purchaser, "PURCHASER");

        (
            address _lender,
            address _demoTokenAddress,
            uint256 _oldLoanState
        ) = _debtSetup(_contractTerms, _collateralId, _borrower, _debtId);

        // Execute debt exchange.
        vm.recordLogs();
        bool _success = anzaDebtExchangeHarness.exposed__executeDebtExchange(
            _demoTokenAddress,
            _collateralId,
            _borrower,
            _purchaser,
            _payment
        );

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        assertTrue(_success, "1 :: debt exchange should succeed");
        assertEq(
            anzaTokenHarness.borrowerOf(_debtId),
            _purchaser,
            "2 :: borrower should be _purchaser"
        );

        console.log(loanContractHarness.debtBalance(_debtId), _payment);

        if (_payment >= _contractTerms.principal) {
            assertEq(
                anzaTokenHarness.lenderOf(_debtId),
                address(0),
                "3 :: lender should be address(0)"
            );
        } else {
            assertEq(
                anzaTokenHarness.lenderOf(_debtId),
                _lender,
                "4 :: lender should be _lender"
            );
        }

        uint256 _currentEntry = 0;
        if (_payment != 0) {
            uint256 _expectedPayment = _contractTerms.principal > _payment
                ? _payment
                : _contractTerms.principal;

            // Burn lender token (PaymentBook._depositPayment).
            _testTransferSingle(
                _entries[_currentEntry++],
                TransferSingleFields({
                    operator: address(anzaDebtExchangeHarness),
                    from: _lender,
                    to: address(0),
                    id: _debtId.debtIdToLenderTokenId(),
                    value: _expectedPayment
                })
            );

            // PaymentBook._depositPayment
            _testDeposited(
                _entries[_currentEntry++],
                DepositedFields({
                    debtId: _debtId,
                    payer: _purchaser,
                    payee: _lender,
                    weiAmount: _expectedPayment
                })
            );

            if (_payment >= _contractTerms.principal)
                // LoanAccountant.debUpdater >> __updateLoanStates
                _testLoanStateChanged(
                    _entries[_currentEntry++],
                    LoanStateChangedFields({
                        debtId: _debtId,
                        newLoanState: _PAID_STATE_,
                        oldLoanState: uint8(_oldLoanState)
                    })
                );

            if (_payment > _contractTerms.principal) {
                uint256 _remainingPayment = _payment - _contractTerms.principal;

                // AnzaDebtExchange._executeDebtExchange (remaining balance transfer).
                _testDeposited(
                    _entries[_currentEntry++],
                    DepositedFields({
                        debtId: type(uint256).max,
                        payer: _purchaser,
                        payee: _borrower,
                        weiAmount: _remainingPayment
                    })
                );
            }
        }

        uint256[] memory _ids = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);

        _ids[0] = _debtId.debtIdToBorrowerTokenId();
        _amounts[0] = 1;

        // AnzaToken.safeBatchTransferFrom (transfer borrower tokens to new debt
        // owner/borrower).
        _testTransferBatch(
            _entries[_currentEntry],
            TransferBatchFields({
                operator: address(anzaDebtExchangeHarness),
                from: _borrower,
                to: _purchaser,
                ids: _ids,
                values: _amounts
            })
        );
    }

    /* ------ AnzaDebtExchange._depositPayment() ------- */
    function testAnzaDebtExchange__depositPayment(
        ContractTerms memory _contractTerms,
        uint256 _debtId,
        uint256 _payment
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

        // AnzaToken mint.
        anzaTokenHarness.exposed__mint(
            borrower,
            _debtId.debtIdToBorrowerTokenId(),
            1
        );
        anzaTokenHarness.exposed__mint(
            lender,
            _debtId.debtIdToLenderTokenId(),
            _contractTerms.principal
        );

        // Expire loan.
        vm.warp(_now + _contractTerms.gracePeriod + _contractTerms.duration);

        vm.expectRevert(_EXPIRED_LOAN_SELECTOR_);
        anzaDebtExchangeHarness.exposed__depositPayment(
            alt_account,
            _debtId,
            _payment
        );

        // Activate loan.
        vm.warp(_now);

        // Deposit payment (__updatePermitted == false).
        uint256 _remainingPayment = anzaDebtExchangeHarness
            .exposed__depositPayment(alt_account, _debtId, _payment);

        assertEq(
            _remainingPayment,
            _payment,
            "0 :: _remainingPayment should match expected"
        );

        // Deposit payment (__updatePermitted == true).
        _remainingPayment = anzaDebtExchangeHarness
            .exposed__depositPayment_updatePermitted(
                alt_account,
                _debtId,
                _payment
            );

        uint256 _expectedRemainingPayment = _contractTerms.principal > _payment
            ? 0
            : _payment - _contractTerms.principal;

        assertEq(
            _remainingPayment,
            _expectedRemainingPayment,
            "1 :: _remainingPayment should match expected"
        );
    }
}
