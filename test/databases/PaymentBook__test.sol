// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Vm, stdError} from "forge-std/Test.sol";

import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_PRINCIPAL_, _MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";

import {PaymentBook} from "@lending-databases/PaymentBook.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {IPaymentBookEvents, PaymentBookEventsSuite} from "@test-utils/events/PaymentBookEventsSuite__test.sol";

contract PaymentBookHarness is PaymentBook {
    function exposed__depositFunds(
        uint256 _debtId,
        address _payer,
        address _payee,
        uint256 _amount
    ) public {
        _depositFunds(_debtId, _payer, _payee, _amount);
    }

    function exposed__withdrawFunds(address _account, uint256 _amount) public {
        _withdrawFunds(_account, _amount);
    }

    function exposed__depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) public returns (uint256) {
        return _depositPayment(_payer, _debtId, _payment);
    }

    /* Abstract functions */
    function setAnzaToken(address _anzaTokenAddress) public override {
        super._setAnzaToken(_anzaTokenAddress);
    }
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract PaymentBookInit is Setup {
    PaymentBookHarness internal paymentBookHarness;
    AnzaTokenHarness internal anzaTokenHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy PaymentBook
        paymentBookHarness = new PaymentBookHarness();

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();

        // Set AnzaToken access control roles
        anzaTokenHarness.grantRole(_TREASURER_, address(paymentBookHarness));

        // Set LoanTreasurey access control roles
        paymentBookHarness.setAnzaToken(address(anzaTokenHarness));

        vm.stopPrank();
    }
}

contract PaymentBookUnitTest is
    PaymentBookInit,
    IPaymentBookEvents,
    PaymentBookEventsSuite
{
    using AnzaTokenIndexer for uint256;

    function setUp() public override {
        super.setUp();
    }

    function _depositFunds(address _payee, uint256 _amount) internal {
        vm.deal(address(this), _amount);

        vm.recordLogs();
        (bool _success, ) = address(paymentBookHarness).call{value: _amount}(
            abi.encodeWithSignature("depositFunds(address)", _payee)
        );
        require(_success, "0 :: funds deposit should succeed.");
    }

    /* ------------- PaymentBook.depositFunds() ------------- */
    /**
     * Fuzz test the deposit funds function.
     *
     * @dev This test is on the depositFunds(address) function.
     *
     * @param _payer The payer to deposit funds.
     * @param _payee The account to receive funds in their withdrawable balance.
     * @param _amount The amount to deposit.
     *
     * @notice This function is payable.
     *
     * Emits a {Deposited} event.
     *
     * @dev Full pass if the deposit succeeds.
     */
    function testPaymentBook_DepositFunds_Fuzz_Basic(
        address _payer,
        address _payee,
        uint128 _amount
    ) public {
        vm.deal(_payer, _amount);
        vm.startPrank(_payer);
        vm.recordLogs();
        (bool _success, bytes memory _data) = address(paymentBookHarness).call{
            value: _amount
        }(abi.encodeWithSignature("depositFunds(address)", _payee));
        vm.stopPrank();

        bool _results = abi.decode(_data, (bool));

        assertTrue(_success, "0 :: funds deposit should succeed.");
        assertTrue(_results, "1 :: funds deposit should succeed.");

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        _testDeposited(
            _entries[0],
            DepositedFields({
                debtId: type(uint256).max,
                payer: _payer,
                payee: _payee,
                weiAmount: _amount
            })
        );
    }

    /* ------------- PaymentBook.depositFunds() ------------- */
    /**
     * Fuzz test the deposit funds function.
     *
     * @dev This test is on the depositFunds(uint256,address,address) function.
     *
     * @param _payer The payer to deposit funds.
     * @param _payee The account to receive funds in their withdrawable balance.
     * @param _amount The amount to deposit.
     *
     * @notice This function is payable.
     *
     * Emits a {Deposited} event.
     *
     * @dev Full pass if the deposit succeeds.
     */
    function testPaymentBook_DepositFunds_Fuzz_Args(
        address _payer,
        address _payee,
        uint128 _amount,
        uint256 _debtId
    ) public {
        vm.deal(address(this), _amount);

        vm.recordLogs();
        (bool _success, bytes memory _data) = address(paymentBookHarness).call{
            value: _amount
        }(
            abi.encodeWithSignature(
                "depositFunds(uint256,address,address)",
                _debtId,
                _payer,
                _payee
            )
        );

        bool _results = abi.decode(_data, (bool));

        assertTrue(_success, "0 :: funds deposit should succeed.");
        assertTrue(_results, "1 :: funds deposit should succeed.");

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        _testDeposited(
            _entries[0],
            DepositedFields({
                debtId: _debtId,
                payer: _payer,
                payee: _payee,
                weiAmount: _amount
            })
        );
    }

    /* --------- PaymentBook.withdrawableBalance() ---------- */
    /**
     * Fuzz test the withdrawable balance function.
     *
     * @param _payee The account to check the withdrawable balance.
     * @param _amount The amount to deposit.
     *
     * @dev Full pass if the withdrawable balance is equal to the amount
     * deposited.
     */
    function testPaymentBook_WithdrawableBalance_Fuzz(
        address _payee,
        uint128 _amount
    ) public {
        _depositFunds(_payee, _amount);

        assertEq(
            paymentBookHarness.withdrawableBalance(_payee),
            _amount,
            "1 :: withdrawable balance should be equal to the amount deposited."
        );

        assertEq(
            paymentBookHarness.withdrawableBalance(address(this)),
            0,
            "2 :: withdrawable balance should be equal to the amount deposited."
        );
    }

    /* ------------- PaymentBook._depositFunds() ------------- */
    /**
     * See testPaymentBook_DepositFunds_Fuzz and
     * testPaymentBook_DepositFunds_Fuzz_Args.
     */

    /* ------------ PaymentBook._withdrawFunds() ------------- */
    /**
     * Fuzz test the withdraw funds function.
     */
    function testPaymentBook__WithdrawFunds_Fuzz(
        address _payee,
        uint128 _amount
    ) public {
        vm.assume(_amount > 0);

        // Fail if the withdrawable balance is zero.
        vm.expectRevert(stdError.arithmeticError);
        paymentBookHarness.exposed__withdrawFunds(_payee, _amount);

        _depositFunds(_payee, _amount);

        // Fail if the withdrawable balance is less than the amount.
        vm.expectRevert(stdError.arithmeticError);
        paymentBookHarness.exposed__withdrawFunds(_payee, _amount + 1);

        // Pass if the withdrawable balance is equal to the amount.
        vm.recordLogs();
        paymentBookHarness.exposed__withdrawFunds(_payee, _amount);

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        _testWithdrawn(
            _entries[0],
            WithdrawnFields({payee: _payee, weiAmount: _amount})
        );
    }

    /* ------------ PaymentBook._depositPayment() ------------- */
    /**
     * Fuzz test the deposit payment function.
     */
    function testPaymentBook__DepositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _balance,
        uint128 _payment
    ) public {
        vm.assume(_debtId <= _MAX_DEBT_ID_);
        _balance = bound(_balance, 0, _MAX_DEBT_PRINCIPAL_);

        assertEq(
            paymentBookHarness.withdrawableBalance(lender),
            0,
            "0 :: withdrawable balance should be 0."
        );

        // Test with no lender Anza Tokens minted.
        vm.recordLogs();
        uint256 _excess = paymentBookHarness.exposed__depositPayment(
            _payer,
            _debtId,
            uint256(_payment)
        );

        // Get logs.
        Vm.Log[] memory _entries = vm.getRecordedLogs();

        assertEq(_excess, _payment, "1 :: excess should be equal to payment.");
        assertEq(_entries.length, 0, "2 :: no logs should be emitted.");
        assertEq(
            paymentBookHarness.withdrawableBalance(lender),
            0,
            "3 :: withdrawable balance should be 0."
        );

        if (_balance == 0 || _payment == 0) return;

        // Test with lender Anza Tokens minted.
        anzaTokenHarness.exposed__mint(
            lender,
            _debtId.debtIdToLenderTokenId(),
            _balance
        );

        vm.expectEmit(true, true, true, true, address(paymentBookHarness));
        emit Deposited(
            _debtId,
            _payer,
            lender,
            _payment > _balance ? _balance : _payment
        );
        _excess = paymentBookHarness.exposed__depositPayment(
            _payer,
            _debtId,
            uint256(_payment)
        );

        assertEq(
            paymentBookHarness.withdrawableBalance(lender),
            _payment > _balance ? _balance : _payment,
            "4 :: withdrawable balance should be equal to amount deposited."
        );
        assertEq(
            _excess,
            _payment > _balance ? _payment - _balance : 0,
            "5 :: excess should be equal to payment less balance."
        );

        // Payoff if necessary.
        if (_balance > _payment) {
            vm.expectEmit(true, true, true, true, address(paymentBookHarness));
            emit Deposited(_debtId, _payer, lender, _balance - _payment);
            _excess = paymentBookHarness.exposed__depositPayment(
                _payer,
                _debtId,
                _balance
            );

            assertEq(
                paymentBookHarness.withdrawableBalance(lender),
                _balance,
                "4 :: withdrawable balance should be equal to total amount of AnzaTokens minted."
            );
            assertEq(
                _excess,
                _balance - (_balance - _payment),
                "5 :: excess should be balance less payment."
            );
            assertEq(
                anzaTokenHarness.balanceOf(
                    lender,
                    _debtId.debtIdToLenderTokenId()
                ),
                0,
                "6 :: lender AnzaTokens should be 0."
            );
        }
    }
}
