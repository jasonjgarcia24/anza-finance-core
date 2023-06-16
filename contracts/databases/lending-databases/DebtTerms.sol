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

    /**
     * Returns the packed debt terms for a given debt ID.
     *
     * @param _debtId The debt ID to return the packed debt terms for.
     *
     * See {LibLoanCodecIndexer._debtTerms}.
     *
     * @return The packed debt terms for the given debt ID.
     */
    function debtTerms(uint256 _debtId) public view returns (bytes32) {
        return __packedDebtTerms._debtTerms(_debtId);
    }

    /**
     * Sets the packed debt terms for a given debt ID.
     *
     * @param _debtId The debt ID to set the packed debt terms for.
     *
     * See {LibLoanCodecIndexer._setDebtTerms}.
     */
    function _setDebtTerms(uint256 _debtId, bytes32 _packedDebtTerms) internal {
        __packedDebtTerms._setDebtTerms(_debtId, _packedDebtTerms);
    }

    /**
     * Returns the loan state for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan state for.
     *
     * See {LibLoanCodecIndexer._loanState}.
     *
     * @return The loan state for the given debt ID.
     */
    function loanState(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanState(_debtId);
    }

    /**
     * Returns the fixed interest rate (FIR) interval for a given debt ID.
     *
     * @param _debtId The debt ID to return the FIR interval for.
     *
     * See {LibLoanCodecIndexer._firInterval}.
     *
     * @return The FIR interval for the given debt ID.
     */
    function firInterval(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._firInterval(_debtId);
    }

    /**
     * Returns the fixed interest rate (FIR) for a given debt ID.
     *
     * @param _debtId The debt ID to return the FIR for.
     *
     * See {LibLoanCodecIndexer._fixedInterestRate}.
     *
     * @return The FIR for the given debt ID.
     */
    function fixedInterestRate(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._fixedInterestRate(_debtId);
    }

    /**
     * Returns the is fixed status for a given debt ID.
     *
     * @param _debtId The debt ID to return the is fixed status for.
     *
     * See {LibLoanCodecIndexer._isFixed}.
     *
     * @return The is fixed status for the given debt ID.
     */
    function isFixed(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._isFixed(_debtId);
    }

    /**
     * Returns the loan last checked timestamp for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan last checked
     * timestamp for.
     *
     * See {LibLoanCodecIndexer._loanLastChecked}.
     *
     * @return The loan last checked timestamp for the given debt ID.
     */
    function loanLastChecked(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanLastChecked(_debtId);
    }

    /**
     * Returns the loan start timestamp for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan start timestamp for.
     *
     * See {LibLoanCodecIndexer._loanStart}.
     *
     * @return The loan start timestamp for the given debt ID.
     */
    function loanStart(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanStart(_debtId);
    }

    /**
     * Returns the loan duration for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan duration for.
     *
     * See {LibLoanCodecIndexer._loanDuration}.
     *
     * @return The loan duration for the given debt ID.
     */
    function loanDuration(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanDuration(_debtId);
    }

    /**
     * Returns the loan commital duration for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan commital duration for.
     *
     * See {LibLoanCodecIndexer._loanCommital}.
     *
     * @return The loan commital duration for the given debt ID.
     */
    function loanCommital(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanCommital(_debtId);
    }

    /**
     * Returns the loan close timestamp for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan close timestamp for.
     *
     * See {LibLoanCodecIndexer._loanClose}.
     *
     * @return The loan close timestamp for the given debt ID.
     */
    function loanClose(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanClose(_debtId);
    }

    /**
     * Returns the lender royalties on a refinance transaction to another lender.
     *
     * @param _debtId The debt ID to return the lender royalties for.
     *
     * See {LibLoanCodecIndexer._lenderRoyalties}.
     *
     * @return The lender royalties for the given debt ID.
     */
    function lenderRoyalties(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._lenderRoyalties(_debtId);
    }

    /**
     * Returns the active loan count of a given collateralized token.
     * 
     * TODO: This is not used anywhere, remove? It is also captured in 
     * the DebtMaps database.
     *
     * @param _debtId The debt ID to return the active loan count for.
     *
     * See {LibLoanCodecIndexer._activeLoanCount}.
     *
     * @return The active loan count for the given debt ID.
     */
    function activeLoanCount(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._activeLoanCount(_debtId);
    }
}
