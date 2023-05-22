// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../contracts/domain/LoanContractFIRIntervals.sol";
import "../contracts/domain/LoanContractRoles.sol";
import "../contracts/domain/LoanContractStates.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ILoanContractEvents} from "./interfaces/ILoanContractEvents.t.sol";
import {LoanContract} from "../contracts/LoanContract.sol";
import {CollateralVault} from "../contracts/CollateralVault.sol";
import {LoanTreasurey} from "../contracts/LoanTreasurey.sol";
import {ILoanContract} from "../contracts/interfaces/ILoanContract.sol";
import {ILoanCodec} from "../contracts/interfaces/ILoanCodec.sol";
import {ILoanTreasurey} from "../contracts/interfaces/ILoanTreasurey.sol";
import {DemoToken} from "../contracts/utils/DemoToken.sol";
import {AnzaToken} from "../contracts/token/AnzaToken.sol";
import {LibLoanContractSigning as Signing, LibLoanContractTerms as Terms} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractStates, LibLoanContractFIRIntervals, LibLoanContractFIRIntervalMultipliers} from "../contracts/libraries/LibLoanContractConstants.sol";
import {Utils, Setup} from "./Setup.t.sol";

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

        // contractTerms = createContractTerms();
        // signature = createContractSignature(
        //     collateralId,
        //     collateralNonce,
        //     contractTerms
        // );
    }
}

abstract contract LoanContractSubmitted is LoanSigned {
    function setUp() public virtual override {
        super.setUp();

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        // Create loan contract
        createLoanContract(collateralId);
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
        loanContract.setLoanTreasurer(address(loanTreasurer));
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

    function testLoanContract__SetMaxRefinances() public {
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

    function testLoanContract__FuzzSetMaxRefinancesDenyAddress(
        address _account
    ) public {
        vm.assume(_account != admin);

        assertTrue(loanContract.maxRefinances() == 2008, "0 :: Should be 2008");

        // Disallow
        vm.deal(_account, 1 ether);
        vm.startPrank(_account);
        vm.expectRevert(
            bytes(Utils.getAccessControlFailMsg(_ADMIN_, _account))
        );
        loanContract.setMaxRefinances(15);
        vm.stopPrank();

        assertTrue(loanContract.maxRefinances() == 2008, "1 :: Should be 2008");
    }

    function testLoanContract__FuzzSetMaxRefinancesDenyAmount(
        uint256 _amount
    ) public {
        _amount = bound(_amount, 256, type(uint256).max);

        assertTrue(loanContract.maxRefinances() == 2008, "0 :: Should be 2008");

        // Disallow
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        loanContract.setMaxRefinances(_amount);
        vm.stopPrank();

        assertTrue(loanContract.maxRefinances() == 2008, "1 :: Should be 2008");
    }

    function testLoanContract__UpdateLoanStateValidate() public {
        uint256 _debtId = loanContract.totalDebts();

        // Expect to fail for access control
        vm.startPrank(admin);
        vm.expectRevert(bytes(getAccessControlFailMsg(_TREASURER_, admin)));
        loanContract.updateLoanState(_debtId);
        vm.stopPrank();

        // Loan state update should fail because there is no loan
        vm.deal(treasurer, 1 ether);
        vm.startPrank(address(loanTreasurer));
        vm.expectRevert(
            abi.encodeWithSelector(ILoanCodec.InactiveLoanState.selector)
        );
        loanContract.updateLoanState(_debtId);
        vm.stopPrank();

        // Create loan contract
        uint256 _timeLoanCreated = block.timestamp;
        createLoanContract(collateralId);
        _debtId = loanContract.totalDebts();

        // Loan state should remain unchanged
        vm.startPrank(address(loanTreasurer));
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            _ACTIVE_GRACE_STATE_,
            "0 :: Loan state should remain unchanged"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _timeLoanCreated + _GRACE_PERIOD_,
            "1 :: Loan last checked time should remain the loan start time"
        );

        // Loan state should change to _ACTIVE_STATE_
        vm.warp(loanContract.loanStart(_debtId));
        vm.expectEmit(true, true, true, true, address(loanContract));
        emit LoanStateChanged(_debtId, _ACTIVE_STATE_, _ACTIVE_GRACE_STATE_);
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            _ACTIVE_STATE_,
            "2 :: Loan state should change to _ACTIVE_STATE_"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _timeLoanCreated + _GRACE_PERIOD_,
            "3 :: Loan last checked time should remain the loan start time"
        );

        // Loan state should remain _ACTIVE_
        vm.warp(loanContract.loanClose(_debtId) - 1);
        uint256 _now = block.timestamp;
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            _ACTIVE_STATE_,
            "4 :: Loan state should remain _ACTIVE_"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _now,
            "5 :: Loan last checked time should be updated to now"
        );

        // Loan state should change to _DEFAULT_STATE_
        vm.warp(loanContract.loanClose(_debtId));
        vm.expectEmit(true, true, true, true, address(loanContract));
        emit LoanStateChanged(_debtId, _DEFAULT_STATE_, _ACTIVE_STATE_);
        _now = block.timestamp;
        loanContract.updateLoanState(_debtId);
        assertEq(
            loanContract.loanState(_debtId),
            _DEFAULT_STATE_,
            "6 :: Loan state should change to _DEFAULT_STATE_"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _now,
            "7 :: Loan last checked time should be updated to now"
        );
        vm.stopPrank();

        // Loan payoff
        createLoanContract(collateralId + 1);
        _debtId = loanContract.totalDebts();

        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        vm.expectEmit(true, true, true, true, address(loanContract));
        emit LoanStateChanged(_debtId, _PAID_STATE_, _ACTIVE_GRACE_STATE_);
        uint256 _loanStart = loanContract.loanStart(_debtId);
        (bool _success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success, "Payment was unsuccessful");
        assertEq(
            loanContract.loanState(_debtId),
            _PAID_STATE_,
            "8 :: Loan state should be paid in full"
        );
        assertEq(
            loanContract.loanLastChecked(_debtId),
            _loanStart,
            "9 :: Loan last checked time should remain the loan start time"
        );
        vm.stopPrank();
    }

    function testLoanContract__FuzzUpdateLoanStateValidate(
        uint256 _now,
        uint256 _payment
    ) public {
        _payment = bound(_payment, 1, type(uint128).max);
        _now = bound(
            _now,
            block.timestamp - 10,
            block.timestamp + type(uint32).max
        );

        // Create loan contract
        uint256 _timeLoanCreated = block.timestamp;
        (bool _success, ) = address(this).call{value: 0}(
            abi.encodeWithSignature(
                "createLoanContract(uint256)",
                localCollateralId++
            )
        );
        uint256 _debtId = loanContract.totalDebts();

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
                _ACTIVE_STATE_,
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
                _DEFAULT_STATE_,
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
                _PAID_STATE_,
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
            loanContract.debtBalanceOf(_debtId),
            0,
            "0 :: Debt balance for token 0 should be zero"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_,
            "1 :: Debt balance for token 0 should be _PRINCIPAL_"
        );

        // Create loan contract
        createLoanContract(collateralId + 1);
        ++_debtId;

        assertEq(
            loanContract.debtBalanceOf(_debtId),
            _PRINCIPAL_,
            "Debt balance for token 2 should be _PRINCIPAL_"
        );
    }

    function testLoanContract__GetCollateralNonce() public {
        assertEq(
            loanContract.getCollateralNonce(address(demoToken), collateralId),
            1,
            "0 :: Collateral nonce should be one"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.getCollateralNonce(address(demoToken), collateralId),
            2,
            "1 :: Collateral nonce should be two"
        );

        assertEq(
            loanContract.getCollateralNonce(
                address(demoToken),
                collateralId + 1
            ),
            1,
            "2 :: Collateral nonce should be one"
        );
    }

    function testLoanContract__GetCollateralDebtId() public {
        assertEq(
            loanContract.getCollateralDebtId(address(demoToken), collateralId),
            0,
            "0 :: Collateral debt ID should be zero"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertEq(
            loanContract.getCollateralDebtId(address(demoToken), collateralId),
            1,
            "1 :: Collateral debt ID should be one"
        );
    }

    function testLoanContract__GetDebtTerms() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.getDebtTerms(_debtId),
            bytes32(0),
            "0 :: debt terms should be bytes32(0)"
        );

        // Create loan contract
        uint256 _now = block.timestamp;
        createLoanContract(collateralId);
        ++_debtId;

        bytes32 _contractTerms = loanContract.getDebtTerms(_debtId);

        assertTrue(
            _contractTerms != bytes32(0),
            "1 :: debt terms should not be bytes32(0)"
        );

        assertEq(
            Terms.loanState(_contractTerms),
            uint256(_ACTIVE_GRACE_STATE_),
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
            Terms.lenderRoyalties(_contractTerms),
            _LENDER_ROYALTIES_,
            "10 :: loan royalties should be _LENDER_ROYALTIES_"
        );

        assertEq(
            Terms.activeLoanCount(_contractTerms),
            0,
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
        bool _success = createLoanContract(collateralId);
        require(_success, "0 :: loan contract creation failed.");
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
            anzaToken.hasRole(
                keccak256(abi.encodePacked(borrower, ++_debtId)),
                borrower
            ) == false,
            "0 :: loan borrower should not be borrower"
        );

        // Create loan contract
        createLoanContract(collateralId);

        assertTrue(
            anzaToken.hasRole(
                keccak256(abi.encodePacked(borrower, _debtId)),
                borrower
            ),
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

    function testLoanContract__ActiveLoanCount() public {
        uint256 _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.getActiveLoanIndex(address(demoToken), collateralId),
            0,
            "0 :: active loan count should be the default 0"
        );

        // Create loan contract
        createLoanContract(collateralId);
        ++_debtId;

        assertEq(
            loanContract.getActiveLoanIndex(address(demoToken), collateralId),
            1,
            "1 :: active loan count should be 1"
        );

        // Create loan contract partial refinance
        bool _success = refinanceDebt(_debtId);
        require(_success, "2 :: Refinance failed.");
        uint256 _refDebtId = loanContract.totalDebts();

        assertEq(
            loanContract.getActiveLoanIndex(address(demoToken), collateralId),
            2,
            "3 :: active loan count should be 2"
        );

        // Create loan contract partial refinance
        _success = refinanceDebt(_debtId);
        require(_success, "4 :: Refinance failed.");
        _refDebtId = loanContract.totalDebts();

        assertEq(
            loanContract.getActiveLoanIndex(address(demoToken), collateralId),
            3,
            "5 :: active loan count should be 3"
        );

        // Create loan contract partial refinance
        _success = refinanceDebt(_debtId);
        require(_success, "6 :: Refinance failed.");
        _refDebtId = loanContract.totalDebts();

        assertEq(
            loanContract.getActiveLoanIndex(address(demoToken), collateralId),
            4,
            "7 :: active loan count should be 4"
        );
    }

    function testLoanContract__TotalFirIntervals() public {
        // Will manually set values to avoid of loan contract
        // max compounded debt validations

        // Create loan contract
        uint256 _debtId = loanContract.totalDebts();

        bool _success = createLoanContract(
            collateralId,
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
        require(_success, "0 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.totalFirIntervals(_debtId, _SECONDLY_MULTIPLIER_),
            1,
            "1 :: total fir intervals should be 1"
        );

        // Create loan contract
        _success = createLoanContract(
            collateralId + 1,
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
        require(_success, "2 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 2,
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
        require(_success, "5 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 3,
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
        require(_success, "8 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 4,
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
        require(_success, "11 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 5,
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
        require(_success, "14 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 6,
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
        require(_success, "17 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 7,
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
        require(_success, "20 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 8,
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
        require(_success, "23 :: loan contract creation failed.");
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
        _success = createLoanContract(
            collateralId + 9,
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
        require(_success, "26 :: loan contract creation failed.");
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
            abi.encodeWithSelector(ILoanCodec.InactiveLoanState.selector)
        );
        loanContract.verifyLoanActive(_debtId);

        // Create loan contract
        bool _success = createLoanContract(collateralId);
        require(_success, "0 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        loanContract.verifyLoanActive(_debtId);

        // Create loan contract partial refinance
        _success = refinanceDebt(
            _debtId,
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
        require(_success, "1 :: loan contract refinance failed.");
        uint256 _refDebtId = loanContract.totalDebts();

        loanContract.verifyLoanActive(_debtId);
        loanContract.verifyLoanActive(_refDebtId);

        // Create loan contract partial refinance
        _success = refinanceDebt(
            _refDebtId,
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
        require(_success, "2 :: loan contract refinance failed.");

        loanContract.verifyLoanActive(_debtId);

        vm.expectRevert(
            abi.encodeWithSelector(ILoanCodec.InactiveLoanState.selector)
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
        bool _success = createLoanContract(collateralId);
        require(_success, "1 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        assertEq(
            loanContract.checkLoanActive(_debtId),
            true,
            "2 :: loan should be active"
        );

        // Create loan contract partial refinance
        _success = refinanceDebt(
            _debtId,
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
        require(_success, "3 :: loan contract refinance failed.");
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
        _success = refinanceDebt(
            _refDebtId,
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
        require(_success, "6 :: loan contract refinance failed.");

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
        bool _success = createLoanContract(localCollateralId++);
        require(_success, "1 :: loan contract creation failed.");
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
        _success = createLoanContract(localCollateralId++);
        require(_success, "5 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (_success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success, "6 :: Payment was unsuccessful");
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
        bool _success = createLoanContract(localCollateralId++);
        require(_success, "1 :: loan contract creation failed.");
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
        _success = createLoanContract(localCollateralId++);
        require(_success, "4 :: loan contract creation failed.");
        _debtId = loanContract.totalDebts();

        // Pay off loan
        vm.deal(borrower, _PRINCIPAL_);
        vm.startPrank(borrower);
        (_success, ) = address(loanTreasurer).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature("depositPayment(uint256)", _debtId)
        );
        require(_success, "5 :: Payment was unsuccessful");
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
