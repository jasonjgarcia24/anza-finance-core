// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractFIRIntervals.sol";
import "@lending-constants/LoanContractRoles.sol";
import "@lending-constants/LoanContractStates.sol";
import {StdLoanErrors} from "@custom-errors/StdLoanErrors.sol";
import {StdCodecErrors} from "@custom-errors/StdCodecErrors.sol";

import {LoanContract} from "@base/LoanContract.sol";
import {CollateralVault} from "@services/CollateralVault.sol";
import {LoanTreasurey} from "@services/LoanTreasurey.sol";
import {AnzaToken} from "@tokens/AnzaToken.sol";
import {ILoanContract} from "@base/interfaces/ILoanContract.sol";
import {ILoanCodec} from "@services-interfaces/ILoanCodec.sol";
import {ILoanTreasurey} from "@services-interfaces/ILoanTreasurey.sol";
import {LibLoanContractStates, LibLoanContractFIRIntervals, LibLoanContractFIRIntervalMultipliers} from "@helper-libraries/LibLoanContractConstants.sol";

import {Utils, Setup} from "@test-base/Setup__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";
import {ILoanContractEvents} from "@test-contract-interfaces/ILoanContractEvents__test.sol";

abstract contract LoanContractDeployer is Setup, ILoanContractEvents {
    function setUp() public virtual override {
        super.setUp();
    }
}

abstract contract LoanSigned is LoanContractDeployer {
    function setUp() public virtual override {
        super.setUp();

        collateralNonce = loanContract.collateralNonce(
            address(demoToken),
            collateralId
        );
    }
}

abstract contract LoanContractSubmitted is LoanSigned {
    function setUp() public virtual override {
        super.setUp();

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        (bool _success, ) = createLoanContract(collateralId);
        assertTrue(_success, "Contract creation failed.");
        _debtId = loanContract.totalDebts();
    }
}

contract LoanContractConstantsTest is Test {
    function setUp() public virtual {}
}

contract LoanContractSetterUnitTest is LoanContractDeployer {
    uint256 public localCollateralId = collateralId;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(borrower);
        demoToken.mint(300);
        vm.stopPrank();
    }

    function testLoanContract__SetLoanTreasurer() public {
        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "0 :: Should be loan treasurer"
        );

        // Allow
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        loanContract.grantRole(_TREASURER_, address(0));

        assertTrue(
            loanContract.loanTreasurer() == address(0),
            "1 :: Should be address zero"
        );

        // Allow
        loanContract.grantRole(_TREASURER_, address(loanTreasurer));
        vm.stopPrank();

        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "2 :: Should be loan treasurer"
        );
    }

    function testLoanContract__FuzzSetLoanTreasurerDeny(
        address _account
    ) public {
        vm.assume(_account != admin);

        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "0 :: Should be loan treasurer"
        );

        // Disallow
        vm.deal(_account, 1 ether);
        vm.startPrank(_account);
        vm.expectRevert(
            bytes(Utils.getAccessControlFailMsg(_ADMIN_, _account))
        );
        loanContract.grantRole(_TREASURER_, address(loanTreasurer));
        vm.stopPrank();

        assertTrue(
            loanContract.loanTreasurer() == address(loanTreasurer),
            "1 :: Should be loan treasurer"
        );
    }

    function testLoanContract__SetAnzaToken() public {
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

    function testLoanContract__FuzzSetAnzaTokenDeny(address _account) public {
        vm.assume(_account != admin);

        assertTrue(
            loanContract.anzaToken() == address(anzaToken),
            "0 :: Should be AnzaToken"
        );

        // Disallow
        vm.deal(_account, 1 ether);
        vm.startPrank(_account);
        vm.expectRevert(
            bytes(Utils.getAccessControlFailMsg(_ADMIN_, _account))
        );
        loanContract.setAnzaToken(address(anzaToken));
        vm.stopPrank();

        assertTrue(
            loanContract.anzaToken() == address(anzaToken),
            "1 :: Should be AnzaToken"
        );
    }
}

contract LoanContractViewsUnitTest is LoanSigned {
    uint256 public localCollateralId = collateralId;

    function setUp() public virtual override {
        super.setUp();
    }

    function testLoanContract__Pass() public view {}

    function testLoanContract__StateVars() public {
        assertEq(
            loanContract.collateralVault(),
            address(collateralVault),
            "Should match collateralVault"
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

    function testLoanContract__DebtBalanceOf() public {
        uint256 _debtId = 0;

        assertEq(
            loanContract.debtBalance(_debtId),
            0,
            "0 :: Debt balance for token 0 should be zero"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.debtBalance(_debtId),
            _PRINCIPAL_,
            "1 :: Debt balance for token 0 should be _PRINCIPAL_"
        );

        // Create loan contract
        createLoanContract(collateralId + 1);
        ++_debtId;

        assertEq(
            loanContract.debtBalance(_debtId),
            _PRINCIPAL_,
            "Debt balance for token 2 should be _PRINCIPAL_"
        );
    }

    function testLoanContract__GetCollateralNonce() public {
        assertEq(
            loanContract.collateralNonce(address(demoToken), collateralId),
            1,
            "0 :: Collateral nonce should be one"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.collateralNonce(address(demoToken), collateralId),
            2,
            "1 :: Collateral nonce should be two"
        );

        assertEq(
            loanContract.collateralNonce(address(demoToken), collateralId + 1),
            1,
            "2 :: Collateral nonce should be one"
        );
    }

    function testLoanContract__GetCollateralDebtId() public {
        vm.expectRevert(
            abi.encodeWithSelector(StdLoanErrors.InvalidCollateral.selector)
        );
        // ILoanContract.DebtMap memory _debtMap = loanContract.collateralDebtAt(
        (uint256 _debtId, ) = loanContract.collateralDebtAt(
            address(demoToken),
            collateralId,
            type(uint256).max
        );

        // Create loan contract
        createLoanContract(collateralId);

        (_debtId, ) = loanContract.collateralDebtAt(
            address(demoToken),
            collateralId,
            type(uint256).max
        );

        assertEq(_debtId, 1, "1 :: Collateral debt ID should be one");
    }

    function testLoanContract__GetDebtTerms() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.debtTerms(_debtId),
            bytes32(0),
            "0 :: debt terms should be bytes32(0)"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);
        ++_debtId;

        bytes32 _contractTerms = loanContract.debtTerms(_debtId);

        assertTrue(
            _contractTerms != bytes32(0),
            "1 :: debt terms should not be bytes32(0)"
        );

        assertEq(
            loanContract.loanState(_debtId),
            uint256(_ACTIVE_GRACE_STATE_),
            "2 :: loan state should be _ACTIVE_GRACE_STATE_"
        );

        assertEq(
            loanContract.firInterval(_debtId),
            _FIR_INTERVAL_,
            "3 :: fir interval should be _FIR_INTERVAL_"
        );

        assertEq(
            loanContract.fixedInterestRate(_debtId),
            _FIXED_INTEREST_RATE_,
            "4 :: fixed interest rate should be _FIXED_INTEREST_RATE_"
        );

        assertGt(
            loanContract.loanLastChecked(_debtId),
            _now,
            "5 :: loan last checked should be greater than time now"
        );

        assertGt(
            loanContract.loanStart(_debtId),
            _now,
            "6 :: loan start should be greater than time now"
        );

        assertEq(
            loanContract.loanDuration(_debtId),
            _DURATION_,
            "7 :: loan duration should be _DURATION_"
        );

        assertEq(
            loanContract.loanClose(_debtId),
            loanContract.loanStart(_debtId) +
                loanContract.loanDuration(_debtId),
            "8 :: loan close should be the sum of loan start and loan duration"
        );

        assertGt(
            loanContract.loanClose(_debtId),
            _now,
            "9 :: loan close should be greater than time now"
        );

        assertEq(
            loanContract.lenderRoyalties(_debtId),
            _LENDER_ROYALTIES_,
            "10 :: loan royalties should be _LENDER_ROYALTIES_"
        );

        assertEq(
            loanContract.activeLoanCount(_debtId),
            1,
            "11 :: active loan count should be 0"
        );
    }

    function testLoanContract__LoanState() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanState(_debtId),
            uint256(_UNDEFINED_STATE_),
            "0 :: loan state should be _UNDEFINED_STATE_"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.loanState(_debtId),
            uint256(_ACTIVE_GRACE_STATE_),
            "1 :: loan state should be _ACTIVE_GRACE_STATE_"
        );
    }

    function testLoanContract__FirInterval() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.firInterval(_debtId),
            uint256(_SECONDLY_),
            "0 :: fir interval should be the default _SECONDLY_"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.firInterval(_debtId),
            _FIR_INTERVAL_,
            "1 :: fir interval should be _FIR_INTERVAL_"
        );
    }

    function testLoanContract__FixedInterestRate() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.fixedInterestRate(_debtId),
            0,
            "0 :: fixed interest rate should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.fixedInterestRate(_debtId),
            _FIXED_INTEREST_RATE_,
            "1 :: fixed interest rate should be _FIXED_INTEREST_RATE_"
        );
    }

    function testLoanContract__LoanLastChecked() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanLastChecked(_debtId),
            0,
            "0 :: loan last checked should be the default 0"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        (bool _success, ) = createLoanContract(collateralId);
        assertTrue(_success, "0 :: loan contract creation failed.");
        ++_debtId;

        assertGt(
            loanContract.loanLastChecked(_debtId),
            _now,
            "1 :: loan last checked should be greater than time now"
        );
    }

    function testLoanContract__LoanStart() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanStart(_debtId),
            0,
            "0 :: loan start should be the default 0"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);
        ++_debtId;

        assertGt(
            loanContract.loanStart(_debtId),
            _now,
            "1 :: loan start should be greater than time now"
        );
    }

    function testLoanContract__LoanDuration() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanDuration(_debtId),
            0,
            "0 :: loan duration should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.loanDuration(_debtId),
            _DURATION_,
            "1 :: loan duration should be _DURATION_"
        );
    }

    function testLoanContract__LoanClose() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.loanClose(_debtId),
            0,
            "0 :: loan close should be the default 0"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);
        ++_debtId;

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

    function testLoanContract__Borrower() public {
        uint256 _debtId = loanContract.totalDebts();

        assertTrue(
            anzaToken.borrowerOf(++_debtId) != borrower,
            "0 :: loan borrower should not be borrower"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            anzaToken.borrowerOf(_debtId),
            borrower,
            "1 :: loan borrower should be borrower"
        );
    }

    function testLoanContract__LenderRoyalties() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.lenderRoyalties(_debtId),
            0,
            "0 :: loan royalties should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.lenderRoyalties(_debtId),
            _LENDER_ROYALTIES_,
            "1 :: loan royalties should be _LENDER_ROYALTIES_"
        );
    }

    function testLoanContract__CollateralDebtCount() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.collateralDebtCount(address(demoToken), collateralId),
            0,
            "0 :: Collateral debt count should be 0."
        );

        // Create loan contract
        createLoanContract(collateralId);
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.collateralDebtCount(address(demoToken), collateralId),
            1,
            "1 :: Collateral debt count should be 1."
        );

        // Create loan contract partial refinance
        (bool _success, ) = refinanceDebt(
            _debtId,
            borrowerPrivKey,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
        assertTrue(_success, "2 :: Refinance failed.");

        uint256 _refDebtId = loanContract.totalDebts();

        assertEq(
            loanContract.collateralDebtCount(address(demoToken), collateralId),
            2,
            "3 :: Collateral debt count should be 2."
        );

        // Create loan contract partial refinance
        (_success, ) = refinanceDebt(
            _debtId,
            borrowerPrivKey,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
        assertTrue(_success, "4 :: Refinance failed.");

        _refDebtId = loanContract.totalDebts();

        assertEq(
            loanContract.collateralDebtCount(address(demoToken), collateralId),
            3,
            "5 :: Collateral debt count should be 3."
        );

        // Create loan contract partial refinance
        (_success, ) = refinanceDebt(
            _refDebtId,
            borrowerPrivKey,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
        assertTrue(_success, "6 :: Refinance failed.");

        _refDebtId = loanContract.totalDebts();

        assertEq(
            loanContract.collateralDebtCount(address(demoToken), collateralId),
            4,
            "7 :: Collateral debt count should be 4."
        );
    }

    function testLoanContract__TotalFirIntervals() public {
        // Will manually set values to avoid of loan contract
        // max compounded debt validations

        // Create loan contract
        uint256 _debtId = loanContract.totalDebts();
        uint256 _collateralId = collateralId;

        (bool _success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _SECONDLY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_SECONDLY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "0 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _SECONDLY_MULTIPLIER_),
            1,
            "1 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _MINUTELY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_MINUTELY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );

        assertTrue(_success, "2 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _MINUTELY_MULTIPLIER_ - 1),
            0,
            "3 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _MINUTELY_MULTIPLIER_),
            1,
            "4 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _HOURLY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_HOURLY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "5 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _HOURLY_MULTIPLIER_ - 1),
            0,
            "6 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _HOURLY_MULTIPLIER_),
            1,
            "7 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _DAILY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_DAILY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "8 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _DAILY_MULTIPLIER_ - 1),
            0,
            "9 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _DAILY_MULTIPLIER_),
            1,
            "10 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _WEEKLY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_WEEKLY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "11 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _WEEKLY_MULTIPLIER_ - 1),
            0,
            "12 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _WEEKLY_MULTIPLIER_),
            1,
            "13 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _2_WEEKLY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_2_WEEKLY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "14 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _2_WEEKLY_MULTIPLIER_ - 1),
            0,
            "15 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _2_WEEKLY_MULTIPLIER_),
            1,
            "16 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _4_WEEKLY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_4_WEEKLY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "17 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _4_WEEKLY_MULTIPLIER_ - 1),
            0,
            "18 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _4_WEEKLY_MULTIPLIER_),
            1,
            "19 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _6_WEEKLY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_6_WEEKLY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "20 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _6_WEEKLY_MULTIPLIER_ - 1),
            0,
            "21 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _6_WEEKLY_MULTIPLIER_),
            1,
            "22 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _8_WEEKLY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_8_WEEKLY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "23 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _8_WEEKLY_MULTIPLIER_ - 1),
            0,
            "24 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _8_WEEKLY_MULTIPLIER_),
            1,
            "25 :: total fir intervals should be 1"
        );

        // Create loan contract
        (_success, ) = createLoanContract(
            _collateralId++,
            ContractTerms({
                firInterval: _360_DAILY_,
                fixedInterestRate: 1,
                isFixed: 0,
                commital: 0,
                principal: 1,
                gracePeriod: 0,
                duration: uint32(_360_DAILY_MULTIPLIER_),
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: 0
            })
        );
        assertTrue(_success, "26 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _360_DAILY_MULTIPLIER_ - 1),
            0,
            "27 :: total fir intervals should be 0"
        );
        assertEq(
            loanContract.totalFirIntervals(_debtId, _360_DAILY_MULTIPLIER_),
            1,
            "28 :: total fir intervals should be 1"
        );
    }

    function testLoanContract__VerifyLoanActive() public {
        uint256 _debtId = loanContract.totalDebts();

        vm.expectRevert(
            abi.encodeWithSelector(StdCodecErrors.InactiveLoanState.selector)
        );
        loanContract.verifyLoanActive(_debtId);

        // Create loan contract
        (bool _success, ) = createLoanContract(collateralId);
        assertTrue(_success, "0 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        loanContract.verifyLoanActive(_debtId);

        // Create loan contract partial refinance
        (_success, ) = refinanceDebt(
            _debtId,
            borrowerPrivKey,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
        assertTrue(_success, "1 :: loan contract refinance failed.");
        uint256 _refDebtId = loanContract.totalDebts();

        loanContract.verifyLoanActive(_debtId);
        loanContract.verifyLoanActive(_refDebtId);

        // Create loan contract partial refinance
        (_success, ) = refinanceDebt(
            _refDebtId,
            borrowerPrivKey,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
        assertTrue(_success, "2 :: loan contract refinance failed.");

        loanContract.verifyLoanActive(_debtId);

        vm.expectRevert(
            abi.encodeWithSelector(StdCodecErrors.InactiveLoanState.selector)
        );
        loanContract.verifyLoanActive(_refDebtId);
    }

    function testLoanContract__CheckLoanActive() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanActive(_debtId),
            false,
            "0 :: loan should be default inactive"
        );

        // Create loan contract
        (bool _success, ) = createLoanContract(collateralId);
        assertTrue(_success, "1 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanActive(_debtId),
            true,
            "2 :: loan should be active"
        );

        // Create loan contract partial refinance
        (_success, ) = refinanceDebt(
            _debtId,
            borrowerPrivKey,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
        assertTrue(_success, "3 :: loan contract refinance failed.");
        uint256 _refDebtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanActive(_debtId),
            true,
            "4 :: loan should be active"
        );
        assertEq(
            loanContract.checkLoanActive(_refDebtId),
            true,
            "5 :: refinanced loan should be active"
        );

        // Create loan contract partial refinance
        (_success, ) = refinanceDebt(
            _refDebtId,
            borrowerPrivKey,
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_ / 2,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
        assertTrue(_success, "6 :: loan contract refinance failed.");

        assertEq(
            loanContract.checkLoanActive(_debtId),
            true,
            "7 :: loan should be active"
        );
        assertEq(
            loanContract.checkLoanActive(_refDebtId),
            false,
            "8 :: refinanced loan should be inactive"
        );

        _refDebtId = loanContract.totalDebts();
        assertEq(
            loanContract.checkLoanActive(_refDebtId),
            true,
            "9 :: refinanced loan should be active"
        );
    }

    function testLoanContract__CheckLoanDefault() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanDefault(_debtId),
            false,
            "0 :: non existent loan should not be default"
        );

        // Create loan contract
        (bool _success, ) = createLoanContract(localCollateralId++);
        assertTrue(_success, "1 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanDefault(_debtId),
            false,
            "2 :: loan should not be default"
        );

        vm.warp(loanContract.loanClose(_debtId));

        assertEq(
            loanContract.checkLoanDefault(_debtId),
            false,
            "3 :: loan should not be default without an update performed"
        );

        vm.startPrank(address(loanTreasurer));
        loanContract.updateLoanState(_debtId);
        vm.stopPrank();

        assertEq(
            loanContract.checkLoanDefault(_debtId),
            true,
            "4 :: loan should be default with an update performed"
        );

        // Create loan contract
        (_success, ) = createLoanContract(localCollateralId++);
        assertTrue(_success, "5 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (_success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        assertTrue(_success, "6 :: Payment was unsuccessful");
        vm.stopPrank();

        assertEq(
            loanContract.checkLoanDefault(_debtId),
            false,
            "7 :: loan should not be default"
        );

        vm.warp(loanContract.loanClose(_debtId));

        assertEq(
            loanContract.checkLoanDefault(_debtId),
            false,
            "8:: loan should not be default"
        );
    }

    function testLoanContract__CheckLoanExpired() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanExpired(_debtId),
            false,
            "0 :: non existent loan should not be expired"
        );

        // Create loan contract
        (bool _success, ) = createLoanContract(localCollateralId++);
        assertTrue(_success, "1 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanExpired(_debtId),
            false,
            "2 :: loan should not be expired"
        );

        vm.warp(loanContract.loanClose(_debtId));

        assertEq(
            loanContract.checkLoanExpired(_debtId),
            true,
            "2 :: loan should be expired regardless an update performed"
        );

        vm.startPrank(address(loanTreasurer));
        loanContract.updateLoanState(_debtId);
        vm.stopPrank();

        assertEq(
            loanContract.checkLoanExpired(_debtId),
            true,
            "3 :: loan should be expired with an update performed"
        );

        // Create loan contract
        (_success, ) = createLoanContract(localCollateralId++);
        assertTrue(_success, "4 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (_success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        assertTrue(_success, "5 :: Payment was unsuccessful");
        vm.stopPrank();

        assertEq(
            loanContract.checkLoanExpired(_debtId),
            false,
            "6 :: loan should not be expired"
        );

        vm.warp(loanContract.loanClose(_debtId));

        assertEq(
            loanContract.checkLoanExpired(_debtId),
            false,
            "7 :: loan should not be expired"
        );
    }
}
