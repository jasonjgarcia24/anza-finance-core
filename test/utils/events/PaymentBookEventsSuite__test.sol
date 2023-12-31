// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {Bytes32Utils} from "@test-utils/test-utils/Bytes32Utils.sol";

// 0x984a71c9d95fd4794aeba33ae72edfec22053fde75488d63abef9dc69ee795af
bytes32 constant DEPOSITED_EVENT_SIG = keccak256(
    "Deposited(uint256,address,address,uint256)"
);

// 0xdd964f4acb8f706d81d4c25ea78991ac4ab3d72ed57a425733041a4014a0289f
bytes32 constant DEBT_EXCHANGED_EVENT_SIG = keccak256(
    "DebtExchanged(address,uint256,address,address,uint256)"
);

// 0x7084f5476618d8e60b11ef0d7d3f06914655adb8793e28ff7f018d4c76d505d5
bytes32 constant WITHDRAWN_EVENT_SIG = keccak256("Withdrawn(address,uint256)");

interface IPaymentBookEvents {
    event Deposited(
        uint256 indexed debtId,
        address indexed payer,
        address indexed payee,
        uint256 weiAmount
    );

    event DebtExchanged(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        address indexed payer,
        address payee,
        uint256 weiAmount
    );

    event Withdrawn(address indexed payee, uint256 weiAmount);
}

library PaymentBookEventsParse {
    using Bytes32Utils for bytes32;

    function parseDeposited(
        Vm.Log memory _entry
    )
        public
        pure
        returns (
            uint256 _debtId,
            address _payer,
            address _payee,
            uint256 _weiAmount
        )
    {
        require(
            _entry.topics[0] == DEPOSITED_EVENT_SIG,
            "PaymentBookEventsParse: invalid DepositedFields topic"
        );

        _debtId = uint256(_entry.topics[1]);
        _payer = _entry.topics[2].addressFromLast20Bytes();
        (_payee, _weiAmount) = abi.decode(_entry.data, (address, uint256));
    }

    function parseDebtExchanged(
        Vm.Log memory _entry
    )
        public
        pure
        returns (
            address _collateralAddress,
            uint256 _collateralId,
            address _payer,
            address _payee,
            uint256 _weiAmount
        )
    {
        require(
            _entry.topics[0] == DEBT_EXCHANGED_EVENT_SIG,
            "PaymentBookEventsParse: invalid DebtExchangedFields topic"
        );

        _collateralAddress = _entry.topics[1].addressFromLast20Bytes();
        _collateralId = uint256(_entry.topics[2]);
        _payer = _entry.topics[3].addressFromLast20Bytes();
        (_payee, _weiAmount) = abi.decode(_entry.data, (address, uint256));
    }

    function parseWithdrawn(
        Vm.Log memory _entry
    ) public pure returns (address _payee, uint256 _weiAmount) {
        require(
            _entry.topics[0] == WITHDRAWN_EVENT_SIG,
            "PaymentBookEventsParse: invalid WithdrawnFields topic"
        );

        _payee = _entry.topics[1].addressFromLast20Bytes();
        _weiAmount = abi.decode(_entry.data, (uint256));
    }
}

abstract contract PaymentBookEventsSuite is Test {
    struct DepositedFields {
        uint256 debtId;
        address payer;
        address payee;
        uint256 weiAmount;
    }

    struct DebtExchangedFields {
        address collateralAddress;
        uint256 collateralId;
        address payer;
        address payee;
        uint256 weiAmount;
    }

    struct WithdrawnFields {
        address payee;
        uint256 weiAmount;
    }

    function _testDeposited(
        Vm.Log memory _entry,
        DepositedFields memory _expectedValues
    ) internal {
        (
            uint256 _debtId,
            address _payer,
            address _payee,
            uint256 _weiAmount
        ) = PaymentBookEventsParse.parseDeposited(_entry);

        assertEq(
            _debtId,
            _expectedValues.debtId,
            "0 :: _testDeposited :: emitted event debtId mismatch."
        );
        assertEq(
            _payer,
            _expectedValues.payer,
            "1 :: _testDeposited :: emitted event payer mismatch."
        );
        assertEq(
            _payee,
            _expectedValues.payee,
            "2 :: _testDeposited :: emitted event payee mismatch."
        );
        assertEq(
            _weiAmount,
            _expectedValues.weiAmount,
            "3 :: _testDeposited :: emitted event weiAmount mismatch."
        );
    }

    function _testDebtExchange(
        Vm.Log memory _entry,
        DebtExchangedFields memory _expectedValues
    ) internal {
        (
            address _collateralAddress,
            uint256 _collateralId,
            address _payer,
            address _payee,
            uint256 _weiAmount
        ) = PaymentBookEventsParse.parseDebtExchanged(_entry);

        assertEq(
            _collateralAddress,
            _expectedValues.collateralAddress,
            "0 :: _testDebtExchange :: emitted event collateralAddress mismatch."
        );
        assertEq(
            _collateralId,
            _expectedValues.collateralId,
            "1 :: _testDebtExchange :: emitted event collateralId mismatch."
        );
        assertEq(
            _payer,
            _expectedValues.payer,
            "2 :: _testDebtExchange :: emitted event payer mismatch."
        );
        assertEq(
            _payee,
            _expectedValues.payee,
            "3 :: _testDebtExchange :: emitted event payee mismatch."
        );
        assertEq(
            _weiAmount,
            _expectedValues.weiAmount,
            "4 :: _testDebtExchange :: emitted event weiAmount mismatch."
        );
    }

    function _testWithdrawn(
        Vm.Log memory _entry,
        WithdrawnFields memory _expectedValues
    ) internal {
        (address _payee, uint256 _weiAmount) = PaymentBookEventsParse
            .parseWithdrawn(_entry);

        assertEq(
            _payee,
            _expectedValues.payee,
            "0 :: _testWithdrawn :: emitted event payee mismatch."
        );
        assertEq(
            _weiAmount,
            _expectedValues.weiAmount,
            "1 :: _testWithdrawn :: emitted event weiAmount mismatch."
        );
    }
}
