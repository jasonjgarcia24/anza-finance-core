// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ILoanContractEvents} from "./interfaces/ILoanContractEvents.t.sol";
import {LoanContract} from "../contracts/LoanContract.sol";
import {LoanCollateralVault} from "../contracts/LoanCollateralVault.sol";
import {LoanTreasurey} from "../contracts/LoanTreasurey.sol";
import {ILoanContract} from "../contracts/interfaces/ILoanContract.sol";
import {ILoanTreasurey} from "../contracts/interfaces/ILoanTreasurey.sol";
import {DemoToken} from "../contracts/utils/DemoToken.sol";
import {AnzaToken} from "../contracts/token/AnzaToken.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractSigning as Signing, LibLoanContractTerms as Terms} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractConstants, LibLoanContractStates, LibLoanContractFIRIntervals, LibLoanContractFIRIntervalMultipliers, LibLoanContractPackMappings, LibLoanContractStandardErrors} from "../contracts/libraries/LibLoanContractConstants.sol";
import {Utils, Setup, LoanContractHarness} from "./Setup.t.sol";

abstract contract LoanContractDeployer is Setup, ILoanContractEvents {
    function setUp() public virtual override {
        super.setUp();
    }
}

abstract contract LoanSigned is LoanContractDeployer {
    function setUp() public virtual override {
        super.setUp();

        collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        contractTerms = createContractTerms();
        signature = createContractSignature(
            collateralId,
            collateralNonce,
            contractTerms
        );
    }
}

abstract contract LoanContractSubmitted is LoanSigned {
    function setUp() public virtual override {
        super.setUp();

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        // Create loan contract
        createLoanContract(collateralId);

        // Mint replica token
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();
    }

    function mintReplica(uint256 _debtId) public virtual {
        vm.deal(borrower, 1 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();
    }
}

contract LoanContractConstantsTest is Test {
    function setUp() public virtual {}

    function testLoanContractConstants() public {
        LoanContractHarness _loanContractHarness = new LoanContractHarness();

        assertEq(
            _loanContractHarness
                .exposed__SECONDS_PER_24_MINUTES_RATIO_SCALED_(),
            LibLoanContractConstants._SECONDS_PER_24_MINUTES_RATIO_SCALED_,
            "_SECONDS_PER_24_MINUTES_RATIO_SCALED_"
        );
        assertEq(
            _loanContractHarness.exposed__UINT32_MAX_(),
            LibLoanContractConstants._UINT32_MAX_,
            "_UINT32_MAX_"
        );

        assertEq(
            _loanContractHarness.exposed__UNDEFINED_STATE_(),
            LibLoanContractStates._UNDEFINED_STATE_,
            "_UNDEFINED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__NONLEVERAGED_STATE_(),
            LibLoanContractStates._NONLEVERAGED_STATE_,
            "_NONLEVERAGED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__UNSPONSORED_STATE_(),
            LibLoanContractStates._UNSPONSORED_STATE_,
            "_UNSPONSORED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__SPONSORED_STATE_(),
            LibLoanContractStates._SPONSORED_STATE_,
            "_SPONSORED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__FUNDED_STATE_(),
            LibLoanContractStates._FUNDED_STATE_,
            "_FUNDED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__ACTIVE_GRACE_STATE_(),
            LibLoanContractStates._ACTIVE_GRACE_STATE_,
            "_ACTIVE_GRACE_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__ACTIVE_STATE_(),
            LibLoanContractStates._ACTIVE_STATE_,
            "_ACTIVE_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__DEFAULT_STATE_(),
            LibLoanContractStates._DEFAULT_STATE_,
            "_DEFAULT_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__COLLECTION_STATE_(),
            LibLoanContractStates._COLLECTION_STATE_,
            "_COLLECTION_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__AUCTION_STATE_(),
            LibLoanContractStates._AUCTION_STATE_,
            "_AUCTION_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__AWARDED_STATE_(),
            LibLoanContractStates._AWARDED_STATE_,
            "_AWARDED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__PAID_PENDING_STATE_(),
            LibLoanContractStates._PAID_PENDING_STATE_,
            "_PAID_PENDING_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__CLOSE_STATE_(),
            LibLoanContractStates._CLOSE_STATE_,
            "_CLOSE_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__PAID_STATE_(),
            LibLoanContractStates._PAID_STATE_,
            "_PAID_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__CLOSE_DEFAULT_STATE_(),
            LibLoanContractStates._CLOSE_DEFAULT_STATE_,
            "_CLOSE_DEFAULT_STATE_"
        );

        assertEq(
            _loanContractHarness.exposed__SECONDLY_(),
            LibLoanContractFIRIntervals._SECONDLY_,
            "_SECONDLY_"
        );
        assertEq(
            _loanContractHarness.exposed__MINUTELY_(),
            LibLoanContractFIRIntervals._MINUTELY_,
            "_MINUTELY_"
        );
        assertEq(
            _loanContractHarness.exposed__HOURLY_(),
            LibLoanContractFIRIntervals._HOURLY_,
            "_HOURLY_"
        );
        assertEq(
            _loanContractHarness.exposed__DAILY_(),
            LibLoanContractFIRIntervals._DAILY_,
            "_DAILY_"
        );
        assertEq(
            _loanContractHarness.exposed__WEEKLY_(),
            LibLoanContractFIRIntervals._WEEKLY_,
            "_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__2_WEEKLY_(),
            LibLoanContractFIRIntervals._2_WEEKLY_,
            "_2_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__4_WEEKLY_(),
            LibLoanContractFIRIntervals._4_WEEKLY_,
            "_4_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__6_WEEKLY_(),
            LibLoanContractFIRIntervals._6_WEEKLY_,
            "_6_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__8_WEEKLY_(),
            LibLoanContractFIRIntervals._8_WEEKLY_,
            "_8_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__MONTHLY_(),
            LibLoanContractFIRIntervals._MONTHLY_,
            "_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__2_MONTHLY_(),
            LibLoanContractFIRIntervals._2_MONTHLY_,
            "_2_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__3_MONTHLY_(),
            LibLoanContractFIRIntervals._3_MONTHLY_,
            "_3_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__4_MONTHLY_(),
            LibLoanContractFIRIntervals._4_MONTHLY_,
            "_4_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__6_MONTHLY_(),
            LibLoanContractFIRIntervals._6_MONTHLY_,
            "_6_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__360_DAILY_(),
            LibLoanContractFIRIntervals._360_DAILY_,
            "_360_DAILY_"
        );
        assertEq(
            _loanContractHarness.exposed__ANNUALLY_(),
            LibLoanContractFIRIntervals._ANNUALLY_,
            "_ANNUALLY_"
        );

        assertEq(
            _loanContractHarness.exposed__SECONDLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._SECONDLY_MULTIPLIER_,
            "_SECONDLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__MINUTELY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._MINUTELY_MULTIPLIER_,
            "_MINUTELY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__HOURLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._HOURLY_MULTIPLIER_,
            "_HOURLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__DAILY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._DAILY_MULTIPLIER_,
            "_DAILY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._WEEKLY_MULTIPLIER_,
            "_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__2_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._2_WEEKLY_MULTIPLIER_,
            "_2_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__4_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._4_WEEKLY_MULTIPLIER_,
            "_4_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__6_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._6_WEEKLY_MULTIPLIER_,
            "_6_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__8_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._8_WEEKLY_MULTIPLIER_,
            "_8_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__360_DAILY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._360_DAILY_MULTIPLIER_,
            "_360_DAILY_MULTIPLIER_"
        );

        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_MASK_(),
            LibLoanContractPackMappings._LOAN_STATE_MASK_,
            "_LOAN_STATE_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_MAP_(),
            LibLoanContractPackMappings._LOAN_STATE_MAP_,
            "_LOAN_STATE_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_MASK_(),
            LibLoanContractPackMappings._FIR_INTERVAL_MASK_,
            "_FIR_INTERVAL_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_MAP_(),
            LibLoanContractPackMappings._FIR_INTERVAL_MAP_,
            "_FIR_INTERVAL_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_MASK_(),
            LibLoanContractPackMappings._FIR_MASK_,
            "_FIR_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_MAP_(),
            LibLoanContractPackMappings._FIR_MAP_,
            "_FIR_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_START_MASK_(),
            LibLoanContractPackMappings._LOAN_START_MASK_,
            "_LOAN_START_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_START_MAP_(),
            LibLoanContractPackMappings._LOAN_START_MAP_,
            "_LOAN_START_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_DURATION_MASK_(),
            LibLoanContractPackMappings._LOAN_DURATION_MASK_,
            "_LOAN_DURATION_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_DURATION_MAP_(),
            LibLoanContractPackMappings._LOAN_DURATION_MAP_,
            "_LOAN_DURATION_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__BORROWER_MASK_(),
            LibLoanContractPackMappings._BORROWER_MASK_,
            "_BORROWER_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__BORROWER_MAP_(),
            LibLoanContractPackMappings._BORROWER_MAP_,
            "_BORROWER_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LENDER_ROYALTIES_MASK_(),
            LibLoanContractPackMappings._LENDER_ROYALTIES_MASK_,
            "_LENDER_ROYALTIES_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LENDER_ROYALTIES_MAP_(),
            LibLoanContractPackMappings._LENDER_ROYALTIES_MAP_,
            "_LENDER_ROYALTIES_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_COUNT_MASK_(),
            LibLoanContractPackMappings._LOAN_COUNT_MASK_,
            "_LOAN_COUNT_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_COUNT_MAP_(),
            LibLoanContractPackMappings._LOAN_COUNT_MAP_,
            "_LOAN_COUNT_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_POS_(),
            LibLoanContractPackMappings._LOAN_STATE_POS_,
            "_LOAN_STATE_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_POS_(),
            LibLoanContractPackMappings._FIR_INTERVAL_POS_,
            "_FIR_INTERVAL_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_POS_(),
            LibLoanContractPackMappings._FIR_POS_,
            "_FIR_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_START_POS_(),
            LibLoanContractPackMappings._LOAN_START_POS_,
            "_LOAN_START_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_DURATION_POS_(),
            LibLoanContractPackMappings._LOAN_DURATION_POS_,
            "_LOAN_DURATION_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__BORROWER_POS_(),
            LibLoanContractPackMappings._BORROWER_POS_,
            "_BORROWER_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LENDER_ROYALTIES_POS_(),
            LibLoanContractPackMappings._LENDER_ROYALTIES_POS_,
            "_LENDER_ROYALTIES_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_COUNT_POS_(),
            LibLoanContractPackMappings._LOAN_COUNT_POS_,
            "_LOAN_COUNT_POS_"
        );

        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_ERROR_ID_(),
            LibLoanContractStandardErrors._LOAN_STATE_ERROR_ID_,
            "_LOAN_STATE_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_ERROR_ID_(),
            LibLoanContractStandardErrors._FIR_INTERVAL_ERROR_ID_,
            "_FIR_INTERVAL_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__DURATION_ERROR_ID_(),
            LibLoanContractStandardErrors._DURATION_ERROR_ID_,
            "_DURATION_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__PRINCIPAL_ERROR_ID_(),
            LibLoanContractStandardErrors._PRINCIPAL_ERROR_ID_,
            "_PRINCIPAL_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__FIXED_INTEREST_RATE_ERROR_ID_(),
            LibLoanContractStandardErrors._FIXED_INTEREST_RATE_ERROR_ID_,
            "_FIXED_INTEREST_RATE_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__GRACE_PERIOD_ERROR_ID_(),
            LibLoanContractStandardErrors._GRACE_PERIOD_ERROR_ID_,
            "_GRACE_PERIOD_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__TIME_EXPIRY_ERROR_ID_(),
            LibLoanContractStandardErrors._TIME_EXPIRY_ERROR_ID_,
            "_TIME_EXPIRY_ERROR_ID_"
        );
    }
}

contract LoanContractSetterUnitTest is LoanContractDeployer {
    uint256 public localCollateralId = collateralId;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(borrower);
        demoToken.mint(300);
        vm.stopPrank();
    }

    function testSetLoanTreasurer() public {
        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "0 :: Should be loan treasurer"
        );

        // Allow
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        loanContract.setLoanTreasurer(address(0));

        assertTrue(
            loanContract.loanTreasurer() == address(0),
            "1 :: Should be address zero"
        );

        // Allow
        loanContract.setLoanTreasurer(address(loanTreasurer));
        vm.stopPrank();

        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "2 :: Should be loan treasurer"
        );
    }

    function testFuzzSetLoanTreasurerDeny(address _account) public {
        vm.assume(_account != admin);

        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "0 :: Should be loan treasurer"
        );

        // Disallow
        vm.deal(_account, 1 ether);
        vm.startPrank(_account);
        vm.expectRevert(
            bytes(Utils.getAccessControlFailMsg(Roles._ADMIN_, _account))
        );
        loanContract.setLoanTreasurer(address(loanTreasurer));
        vm.stopPrank();

        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "1 :: Should be loan treasurer"
        );
    }

    function testSetAnzaToken() public {
        assertTrue(
            loanContract.anzaToken() == address(anzaToken),
            "0 :: Should be AnzaToken"
        );

        // Allow
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        loanContract.setAnzaToken(address(0));

        assertTrue(
            loanContract.anzaToken() == address(0),
            "1 :: Should be address zero"
        );

        // Allow
        loanContract.setAnzaToken(address(anzaToken));
        vm.stopPrank();

        assertTrue(
            loanContract.anzaToken() == address(anzaToken),
            "2 :: Should be AnzaToken"
        );
    }

    function testFuzzSetAnzaTokenDeny(address _account) public {
        vm.assume(_account != admin);

        assertTrue(
            loanContract.anzaToken() == address(anzaToken),
            "0 :: Should be AnzaToken"
        );

        // Disallow
        vm.deal(_account, 1 ether);
        vm.startPrank(_account);
        vm.expectRevert(
            bytes(Utils.getAccessControlFailMsg(Roles._ADMIN_, _account))
        );
        loanContract.setAnzaToken(address(anzaToken));
        vm.stopPrank();

        assertTrue(
            loanContract.anzaToken() == address(anzaToken),
            "1 :: Should be AnzaToken"
        );
    }

    function testSetMaxRefinances() public {
        assertTrue(loanContract.maxRefinances() == 2008, "0 :: Should be 2008");

        // Allow
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        loanContract.setMaxRefinances(15);

        assertTrue(loanContract.maxRefinances() == 15, "1 :: Should be 15");

        // Allow
        loanContract.setMaxRefinances(255);
        vm.stopPrank();

        assertTrue(loanContract.maxRefinances() == 255, "2 :: Should be 255");
    }

    function testFuzzSetMaxRefinancesDeny(address _account) public {
        vm.assume(_account != admin);

        assertTrue(loanContract.maxRefinances() == 2008, "0 :: Should be 2008");

        // Disallow
        vm.deal(_account, 1 ether);
        vm.startPrank(_account);
        vm.expectRevert(
            bytes(Utils.getAccessControlFailMsg(Roles._ADMIN_, _account))
        );
        loanContract.setMaxRefinances(15);
        vm.stopPrank();

        assertTrue(loanContract.maxRefinances() == 2008, "1 :: Should be 2008");
    }

    function testFuzzSetMaxRefinancesDeny(uint256 _amount) public {
        _amount = bound(_amount, 256, type(uint256).max);

        assertTrue(loanContract.maxRefinances() == 2008, "0 :: Should be 2008");

        // Disallow
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILoanContract.ExceededRefinanceLimit.selector
            )
        );
        loanContract.setMaxRefinances(_amount);
        vm.stopPrank();

        assertTrue(loanContract.maxRefinances() == 2008, "1 :: Should be 2008");
    }

    function testUpdateLoanStateValidate() public {
        uint256 _debtId = loanContract.totalDebts();

        // Expect to fail for access control
        vm.startPrank(admin);
        vm.expectRevert(
            bytes(getAccessControlFailMsg(Roles._TREASURER_, admin))
        );
        loanContract.updateLoanState(_debtId);
        vm.stopPrank();

        // Loan state update should fail because there is no loan
        vm.deal(treasurer, 1 ether);
        vm.startPrank(address(loanTreasurer));
        vm.expectRevert(
            abi.encodeWithSelector(ILoanContract.InactiveLoanState.selector)
        );
        loanContract.updateLoanState(_debtId);
        vm.stopPrank();

        // Create loan contract
        uint256 _timeLoanCreated = block.timestamp;
        createLoanContract(collateralId);
        _debtId = loanContract.totalDebts() - 1;

        // Loan state should remain unchanged
        vm.startPrank(address(loanTreasurer));
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            LibLoanContractStates._ACTIVE_GRACE_STATE_,
            "Loan state should remain unchanged"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _timeLoanCreated + _GRACE_PERIOD_,
            "Loan last checked time should remain the loan start time"
        );

        // Loan state should change to _ACTIVE_STATE_
        vm.warp(loanContract.loanStart(_debtId));
        vm.expectEmit(true, true, true, true, address(loanContract));
        emit LoanStateChanged(
            _debtId,
            LibLoanContractStates._ACTIVE_STATE_,
            LibLoanContractStates._ACTIVE_GRACE_STATE_
        );
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            LibLoanContractStates._ACTIVE_STATE_,
            "Loan state should change to _ACTIVE_STATE_"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _timeLoanCreated + _GRACE_PERIOD_,
            "Loan last checked time should remain the loan start time"
        );

        // Loan state should remain _ACTIVE_
        vm.warp(loanContract.loanClose(_debtId) - 1);
        uint256 _now = block.timestamp;
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            LibLoanContractStates._ACTIVE_STATE_,
            "Loan state should remain _ACTIVE_"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _now,
            "Loan last checked time should be updated to now"
        );

        // Loan state should change to _DEFAULT_STATE_
        vm.warp(loanContract.loanClose(_debtId));
        vm.expectEmit(true, true, true, true, address(loanContract));
        emit LoanStateChanged(
            _debtId,
            LibLoanContractStates._DEFAULT_STATE_,
            LibLoanContractStates._ACTIVE_STATE_
        );
        _now = block.timestamp;
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            LibLoanContractStates._DEFAULT_STATE_,
            "Loan state should change to _DEFAULT_STATE_"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _now,
            "Loan last checked time should be updated to now"
        );
        vm.stopPrank();

        // Loan payoff
        createLoanContract(collateralId + 1);
        _debtId = loanContract.totalDebts() - 1;

        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        vm.expectEmit(true, true, true, true, address(loanContract));
        emit LoanStateChanged(
            _debtId,
            LibLoanContractStates._PAID_STATE_,
            LibLoanContractStates._ACTIVE_GRACE_STATE_
        );
        uint256 _loanStart = loanContract.loanStart(_debtId);
        (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success, "Payment was unsuccessful");
        assertEq(
            loanContract.loanState(_debtId),
            LibLoanContractStates._PAID_STATE_,
            "Loan state should be paid in full"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _loanStart,
            "Loan last checked time should remain the loan start time"
        );
        vm.stopPrank();
    }

    function testFuzzUpdateLoanStateValidate(
        uint256 _now,
        uint256 _payment
    ) public {
        _payment = bound(_payment, 1, type(uint128).max);
        _now = bound(
            _now,
            block.timestamp - 10,
            block.timestamp + type(uint32).max
        );

        uint256 _debtId = loanContract.totalDebts();

        // Create loan contract
        uint256 _timeLoanCreated = block.timestamp;
        (bool _success, ) = address(this).call{value: 0}(
            abi.encodeWithSignature(
                "createLoanContract(uint256)",
                localCollateralId++
            )
        );
        // Ignore conditions where loan terms are invalid. Specifically,
        // scenarios where the calculated compounded interest is beyond
        // the maximum value signed 64.64-bit fixed point number.
        if (!_success) return;

        // Update time
        vm.warp(_now);

        // Set time flags
        uint256 _prevLoanState = loanContract.loanState(_debtId);
        bool _isGracePeriod = _now < (_timeLoanCreated + _GRACE_PERIOD_);
        bool _isExpired = _now >=
            (_timeLoanCreated + _GRACE_PERIOD_ + _DURATION_);

        // Make payment
        vm.deal(borrower, _payment);
        vm.startPrank(borrower);
        uint256 _loanStart = loanContract.loanStart(_debtId);
        (_success, ) = address(loanTreasurer).call{value: _payment}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_isExpired || _success, "Payment was unsuccessful");
        vm.stopPrank();

        // Set state payoff flag
        bool _isPayoff = anzaToken.totalSupply(_debtId * 2) <= 0;

        vm.startPrank(address(loanTreasurer));
        // Loan state should remain unchanged
        if (!_isPayoff && _isGracePeriod) {
            loanContract.updateLoanState(_debtId);
            assertEq(
                loanContract.loanState(_debtId),
                _prevLoanState,
                "0 :: Loan state should remain unchanged"
            );
            assertEq(
                loanContract.loanLastChecked(_debtId),
                _timeLoanCreated + _GRACE_PERIOD_,
                "1 :: Loan last checked time should remain the loan start time"
            );
        }
        // Loan state should change to _ACTIVE_STATE_
        else if (!_isPayoff && !_isGracePeriod && !_isExpired) {
            assertEq(
                loanContract.loanState(_debtId),
                LibLoanContractStates._ACTIVE_STATE_,
                "2 :: Loan state should change to _ACTIVE_STATE_"
            );
            assertEq(
                loanContract.loanLastChecked(_debtId),
                _now,
                "3 :: Loan last checked time should be now"
            );
        }
        // Loan state should change to _DEFAULT_STATE_
        else if (!_isPayoff && _isExpired) {
            assertEq(
                loanContract.loanState(_debtId),
                LibLoanContractStates._DEFAULT_STATE_,
                "4 :: Loan state should change to _DEFAULT_STATE_"
            );
            assertEq(
                loanContract.loanLastChecked(_debtId),
                loanContract.loanClose(_debtId),
                "5 :: Loan last checked time should be updated to loan close time"
            );
        }
        // Loan payoff
        else if (_isPayoff) {
            assertEq(
                loanContract.loanState(_debtId),
                LibLoanContractStates._PAID_STATE_,
                "6 :: Loan state should be paid"
            );
            assertEq(
                loanContract.loanLastChecked(_debtId),
                _isGracePeriod ? _loanStart : _now,
                "7 :: Loan last checked time should be either loan start or now"
            );
        }
        vm.stopPrank();
    }
}

contract LoanContractViewsUnitTest is LoanSigned {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPass() public {}

    function testLoanContractStateVars() public {
        assertEq(
            loanContract.collateralVault(),
            address(loanCollateralVault),
            "Should match loanCollateralVault"
        );

        assertEq(
            loanContract.loanTreasurer(),
            address(loanTreasurer),
            "Should match loanTreasurer"
        );

        assertEq(
            loanContract.anzaToken(),
            address(anzaToken),
            "Should match anzaToken"
        );

        assertEq(
            loanContract.maxRefinances(),
            2008,
            "maxRefinances should currently be 2008"
        );

        assertEq(
            loanContract.totalDebts(),
            0,
            "totalDebts should currently be 0"
        );
    }

    function testDebtBalanceOf() public {
        assertEq(
            loanContract.debtBalanceOf(0),
            0,
            "0 :: Debt balance for token 0 should be zero"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.debtBalanceOf(0),
            _PRINCIPAL_,
            "1 :: Debt balance for token 0 should be _PRINCIPAL_"
        );

        // Create loan contract
        createLoanContract(collateralId + 1);

        assertEq(
            loanContract.debtBalanceOf(1),
            _PRINCIPAL_,
            "Debt balance for token 2 should be _PRINCIPAL_"
        );
    }

    function testGetCollateralNonce() public {
        assertEq(
            loanContract.getCollateralNonce(address(demoToken), collateralId),
            0,
            "0 :: Collateral nonce should be zero"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.getCollateralNonce(address(demoToken), collateralId),
            1,
            "1 :: Collateral nonce should be one"
        );

        assertEq(
            loanContract.getCollateralNonce(
                address(demoToken),
                collateralId + 1
            ),
            0,
            "2 :: Collateral nonce should be zero"
        );
    }

    function testGetCollateralDebtId() public {
        vm.expectRevert(stdError.arithmeticError);
        loanContract.getCollateralDebtId(address(demoToken), collateralId);

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.getCollateralDebtId(address(demoToken), collateralId),
            0,
            "0 :: Collateral debt ID should be zero"
        );
    }

    function testGetDebtTerms() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.getDebtTerms(_debtId),
            bytes32(0),
            "0 :: debt terms should be bytes32(0)"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);

        bytes32 _contractTerms = loanContract.getDebtTerms(_debtId);

        assertTrue(
            _contractTerms != bytes32(0),
            "1 :: debt terms should not be bytes32(0)"
        );

        assertEq(
            Terms.loanState(_contractTerms),
            uint256(LibLoanContractStates._ACTIVE_GRACE_STATE_),
            "2 :: loan state should be _ACTIVE_GRACE_STATE_"
        );

        assertEq(
            Terms.firInterval(_contractTerms),
            _FIR_INTERVAL_,
            "3 :: fir interval should be _FIR_INTERVAL_"
        );

        assertEq(
            Terms.fixedInterestRate(_contractTerms),
            _FIXED_INTEREST_RATE_,
            "4 :: fixed interest rate should be _FIXED_INTEREST_RATE_"
        );

        assertGt(
            Terms.loanLastChecked(_contractTerms),
            _now,
            "5 :: loan last checked should be greater than time now"
        );

        assertGt(
            Terms.loanStart(_contractTerms),
            _now,
            "6 :: loan start should be greater than time now"
        );

        assertEq(
            Terms.loanDuration(_contractTerms),
            _DURATION_,
            "7 :: loan duration should be _DURATION_"
        );

        assertEq(
            Terms.loanClose(_contractTerms),
            Terms.loanStart(_contractTerms) +
                Terms.loanDuration(_contractTerms),
            "8 :: loan close should be the sum of loan start and loan duration"
        );

        assertGt(
            Terms.loanClose(_contractTerms),
            _now,
            "9 :: loan close should be greater than time now"
        );

        assertEq(
            Terms.borrower(_contractTerms),
            borrower,
            "10 :: loan borrower should be borrower"
        );

        assertEq(
            Terms.lenderRoyalties(_contractTerms),
            _LENDER_ROYALTIES_,
            "11 :: loan royalties should be _LENDER_ROYALTIES_"
        );

        assertEq(
            Terms.activeLoanCount(_contractTerms),
            0,
            "12 :: active loan count should be 0"
        );
    }

    function testLoanState() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanState(_debtId),
            uint256(LibLoanContractStates._UNDEFINED_STATE_),
            "0 :: loan state should be _UNDEFINED_STATE_"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.loanState(_debtId),
            uint256(LibLoanContractStates._ACTIVE_GRACE_STATE_),
            "1 :: loan state should be _ACTIVE_GRACE_STATE_"
        );
    }

    function testFirInterval() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.firInterval(_debtId),
            uint256(LibLoanContractFIRIntervals._SECONDLY_),
            "0 :: fir interval should be the default _SECONDLY_"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.firInterval(_debtId),
            _FIR_INTERVAL_,
            "1 :: fir interval should be _FIR_INTERVAL_"
        );
    }

    function testFixedInterestRate() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.fixedInterestRate(_debtId),
            0,
            "0 :: fixed interest rate should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.fixedInterestRate(_debtId),
            _FIXED_INTEREST_RATE_,
            "1 :: fixed interest rate should be _FIXED_INTEREST_RATE_"
        );
    }

    function testLoanLastChecked() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanLastChecked(_debtId),
            0,
            "0 :: loan last checked should be the default 0"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);

        assertGt(
            loanContract.loanLastChecked(_debtId),
            _now,
            "1 :: loan last checked should be greater than time now"
        );
    }

    function testLoanStart() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanStart(_debtId),
            0,
            "0 :: loan start should be the default 0"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);

        assertGt(
            loanContract.loanStart(_debtId),
            _now,
            "1 :: loan start should be greater than time now"
        );
    }

    function testLoanDuration() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanDuration(_debtId),
            0,
            "0 :: loan duration should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.loanDuration(_debtId),
            _DURATION_,
            "1 :: loan duration should be _DURATION_"
        );
    }

    function testLoanClose() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanClose(_debtId),
            0,
            "0 :: loan close should be the default 0"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);

        assertEq(
            loanContract.loanClose(_debtId),
            loanContract.loanStart(_debtId) +
                loanContract.loanDuration(_debtId),
            "1 :: loan close should be the sum of loan start and loan duration"
        );

        assertGt(
            loanContract.loanClose(_debtId),
            _now,
            "2 :: loan close should be greater than time now"
        );
    }

    function testBorrower() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.borrower(_debtId),
            address(0),
            "0 :: loan borrower should be the default address zero"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.borrower(_debtId),
            borrower,
            "1 :: loan borrower should be borrower"
        );
    }

    function testLenderRoyalties() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.lenderRoyalties(_debtId),
            0,
            "0 :: loan royalties should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.lenderRoyalties(_debtId),
            _LENDER_ROYALTIES_,
            "1 :: loan royalties should be _LENDER_ROYALTIES_"
        );
    }

    function testActiveLoanCount() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.activeLoanCount(_debtId),
            0,
            "0 :: active loan count should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.activeLoanCount(_debtId),
            0,
            "1 :: active loan count should be 0"
        );

        // Create loan contract partial refinance
        refinanceDebt(_debtId);

        uint256 _refDebtId = loanContract.totalDebts() - 1;

        assertEq(
            loanContract.activeLoanCount(_refDebtId),
            1,
            "2 :: active loan count should be 1"
        );

        // Create loan contract partial refinance
        refinanceDebt(_debtId);

        _refDebtId = loanContract.totalDebts() - 1;

        assertEq(
            loanContract.activeLoanCount(_refDebtId),
            2,
            "3 :: active loan count should be 2"
        );

        // Create loan contract partial refinance
        refinanceDebt(_refDebtId);

        _refDebtId = loanContract.totalDebts() - 1;

        assertEq(
            loanContract.activeLoanCount(_refDebtId),
            3,
            "4 :: active loan count should be 3"
        );
    }

    function testTotalFirIntervals() public {
        // Create loan contract
        uint256 _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._SECONDLY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._SECONDLY_MULTIPLIER_
            ),
            1,
            "0 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 1,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._MINUTELY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._MINUTELY_MULTIPLIER_ - 1
            ),
            0,
            "1 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._MINUTELY_MULTIPLIER_
            ),
            1,
            "2 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 2,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._HOURLY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._HOURLY_MULTIPLIER_ - 1
            ),
            0,
            "3 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._HOURLY_MULTIPLIER_
            ),
            1,
            "4 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 3,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._DAILY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._DAILY_MULTIPLIER_ - 1
            ),
            0,
            "5 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._DAILY_MULTIPLIER_
            ),
            1,
            "6 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 4,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._WEEKLY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._WEEKLY_MULTIPLIER_ - 1
            ),
            0,
            "7 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._WEEKLY_MULTIPLIER_
            ),
            1,
            "8 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 5,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._2_WEEKLY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._2_WEEKLY_MULTIPLIER_ - 1
            ),
            0,
            "9 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._2_WEEKLY_MULTIPLIER_
            ),
            1,
            "10 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 6,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._4_WEEKLY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._4_WEEKLY_MULTIPLIER_ - 1
            ),
            0,
            "10 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._4_WEEKLY_MULTIPLIER_
            ),
            1,
            "11 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 7,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._6_WEEKLY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._6_WEEKLY_MULTIPLIER_ - 1
            ),
            0,
            "12 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._6_WEEKLY_MULTIPLIER_
            ),
            1,
            "13 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 8,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._8_WEEKLY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._8_WEEKLY_MULTIPLIER_ - 1
            ),
            0,
            "14 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._8_WEEKLY_MULTIPLIER_
            ),
            1,
            "15 :: total fir intervals should be 1"
        );

        // Create loan contract
        _debtId = loanContract.totalDebts();
        createLoanContract(
            collateralId + 9,
            ContractTerms({
                firInterval: LibLoanContractFIRIntervals._360_DAILY_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._360_DAILY_MULTIPLIER_ - 1
            ),
            0,
            "16 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(
                _debtId,
                LibLoanContractFIRIntervalMultipliers._360_DAILY_MULTIPLIER_
            ),
            1,
            "17 :: total fir intervals should be 1"
        );
    }

    function testVerifyLoanActive() public {
        uint256 _debtId = loanContract.totalDebts();

        vm.expectRevert(
            abi.encodeWithSelector(ILoanContract.InactiveLoanState.selector)
        );
        loanContract.verifyLoanActive(_debtId);

        // Create loan contract
        createLoanContract(collateralId);

        loanContract.verifyLoanActive(_debtId);

        // Create loan contract partial refinance
        refinanceDebt(
            _debtId,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        loanContract.verifyLoanActive(_debtId);

        uint256 _refDebtId = loanContract.totalDebts() - 1;
        loanContract.verifyLoanActive(_refDebtId);

        // Create loan contract partial refinance
        refinanceDebt(
            _refDebtId,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        loanContract.verifyLoanActive(_debtId);

        vm.expectRevert(
            abi.encodeWithSelector(ILoanContract.InactiveLoanState.selector)
        );
        loanContract.verifyLoanActive(_refDebtId);
    }

    function testCheckLoanActive() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanActive(_debtId),
            false,
            "0 :: loan should be inactive"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.checkLoanActive(_debtId),
            true,
            "1 :: loan should be active"
        );

        // Create loan contract partial refinance
        refinanceDebt(
            _debtId,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.checkLoanActive(_debtId),
            true,
            "2 :: loan should be active"
        );

        uint256 _refDebtId = loanContract.totalDebts() - 1;
        assertEq(
            loanContract.checkLoanActive(_refDebtId),
            true,
            "3 :: refinanced loan should be active"
        );

        // Create loan contract partial refinance
        refinanceDebt(
            _refDebtId,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );

        assertEq(
            loanContract.checkLoanActive(_debtId),
            true,
            "4 :: loan should be active"
        );

        assertEq(
            loanContract.checkLoanActive(_refDebtId),
            false,
            "5 :: refinanced loan should be inactive"
        );
    }
}
