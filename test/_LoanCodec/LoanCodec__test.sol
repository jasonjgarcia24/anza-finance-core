// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";

import {LoanCodec} from "@base/LoanCodec.sol";

contract LoanCodecHarness is LoanCodec {
    function exposed__validateLoanTerms(
        bytes32 _contractTerms,
        uint64 _loanStart,
        uint256 _principal
    ) public view {
        _validateLoanTerms(_contractTerms, _loanStart, _principal);
    }

    function exposed__getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) public view returns (uint256) {
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

    function exposed__setLoanState(
        uint256 _debtId,
        uint8 _newLoanState
    ) public {
        _setLoanState(_debtId, _newLoanState);
    }

    function exposed__updateLoanTimes(uint256 _debtId) public {
        _updateLoanTimes(_debtId);
    }

    /* Abstract functions */
    /* ^^^^^^^^^^^^^^^^^^ */
}
