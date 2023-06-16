// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IDebtTerms} from "@lending-databases/interfaces/IDebtTerms.sol";
import {LibLoanCodecIndexer as Indexer} from "@lending-libraries/LibLoanCodec.sol";

abstract contract DebtTerms is IDebtTerms {
    using Indexer for Indexer.DebtTermMap;

    /**
     *  > 004 - [0..3]     `loanState`
     *  > 004 - [4..7]     `firInterval`
     *  > 008 - [8..15]    `fixedInterestRate`
     *  > 064 - [16..79]   `loanStart`
     *  > 032 - [80..111]  `loanDuration`
     *  > 004 - [112..115] `isFixed`
     *  > 008 - [116..123] `commital`
     *  > 160 - [124..239]  unused space
     *  > 008 - [240..247] `lenderRoyalties`
     *  > 008 - [248..255] `activeLoanIndex`
     */
    Indexer.DebtTermMap private __packedDebtTerms;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IDebtTerms).interfaceId;
    }

    function debtTerms(uint256 _debtId) public view returns (bytes32) {
        return __packedDebtTerms._debtTerms(_debtId);
    }

    function _setDebtTerms(uint256 _debtId, bytes32 _packedDebtTerms) internal {
        __packedDebtTerms._setDebtTerms(_debtId, _packedDebtTerms);
    }

    function loanState(
        uint256 _debtId
    ) public view returns (uint256 _uLoanState) {
        return __packedDebtTerms._loanState(_debtId);
    }

    function firInterval(
        uint256 _debtId
    ) public view returns (uint256 _uFirInterval) {
        return __packedDebtTerms._firInterval(_debtId);
    }

    function fixedInterestRate(
        uint256 _debtId
    ) public view returns (uint256 _uFixedInterestRate) {
        return __packedDebtTerms._fixedInterestRate(_debtId);
    }

    function isFixed(uint256 _debtId) public view returns (uint256 _isFixed) {
        return __packedDebtTerms._isFixed(_debtId);
    }

    function loanLastChecked(
        uint256 _debtId
    ) public view returns (uint256 _loanLastChecked) {
        return __packedDebtTerms._loanLastChecked(_debtId);
    }

    function loanStart(
        uint256 _debtId
    ) public view returns (uint256 _loanStart) {
        return __packedDebtTerms._loanStart(_debtId);
    }

    function loanDuration(
        uint256 _debtId
    ) public view returns (uint256 _loanDuration) {
        return __packedDebtTerms._loanDuration(_debtId);
    }

    function loanCommital(
        uint256 _debtId
    ) public view returns (uint256 _commital) {
        return __packedDebtTerms._loanCommital(_debtId);
    }

    function loanClose(
        uint256 _debtId
    ) public view returns (uint256 _loanClose) {
        return __packedDebtTerms._loanClose(_debtId);
    }

    function lenderRoyalties(
        uint256 _debtId
    ) public view returns (uint256 _lenderRoyalties) {
        return __packedDebtTerms._lenderRoyalties(_debtId);
    }

    function activeLoanCount(
        uint256 _debtId
    ) public view returns (uint256 _activeLoanCount) {
        return __packedDebtTerms._activeLoanCount(_debtId);
    }
}
