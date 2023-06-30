// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {Bytes32Utils} from "@test-utils/test-utils/Bytes32Utils.sol";

// 0x361d0bb4f0b625387fc860030dd8ba1ec262c62d85ec5ded355aa4e43e632964
bytes32 constant LOAN_STATE_CHANGED_EVENT_SIG = keccak256(
    "LoanStateChanged(uint256,uint8,uint8)"
);

interface ILoanCodecEvents {
    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );
}

library LoanCodecEventsParse {
    using Bytes32Utils for bytes32;

    function parseLoanStateChanged(
        Vm.Log memory _entry
    )
        public
        pure
        returns (uint256 _debtId, uint8 _newLoanState, uint8 _oldLoanState)
    {
        require(
            _entry.topics[0] == LOAN_STATE_CHANGED_EVENT_SIG,
            "LoanCodecEventsParse: invalid LoanStateChanged topic"
        );

        _debtId = uint256(_entry.topics[1]);
        _newLoanState = uint8(uint256(_entry.topics[2]));
        _oldLoanState = uint8(uint256(_entry.topics[3]));
    }
}

abstract contract LoanCodecEventsSuite is Test {
    struct LoanStateChangedFields {
        uint256 debtId;
        uint8 newLoanState;
        uint8 oldLoanState;
    }

    function _testLoanStateChanged(
        Vm.Log memory _entry,
        LoanStateChangedFields memory _expectedValues
    ) internal {
        (
            uint256 _debtId,
            uint8 _newLoanState,
            uint8 _oldLoanState
        ) = LoanCodecEventsParse.parseLoanStateChanged(_entry);

        assertEq(
            _debtId,
            _expectedValues.debtId,
            "0 :: _testLoanStateChanged :: emitted event debtId mismatch."
        );
        assertEq(
            _newLoanState,
            _expectedValues.newLoanState,
            "1 :: _testLoanStateChanged :: emitted event newLoanState mismatch."
        );
        assertEq(
            _oldLoanState,
            _expectedValues.oldLoanState,
            "2 :: _testLoanStateChanged :: emitted event oldLoanState mismatch."
        );
    }
}
