// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IDebtTerms} from "@lending-databases/interfaces/IDebtTerms.sol";
import {DebtTermIndexer as Indexer} from "@lending-libraries/DebtTermIndexer.sol";

abstract contract DebtTerms is IDebtTerms {
    using Indexer for Indexer.DebtTermMap;

    /**
     * The packed debt terms for each debt ID.
     *
     * See {DebtTermIndexer.packedDebtTerms}.
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
     * See {DebtTermIndexer._debtTerms}.
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
     * See {DebtTermIndexer._setDebtTerms}.
     */
    function _setDebtTerms(uint256 _debtId, bytes32 _packedDebtTerms) internal {
        __packedDebtTerms._setDebtTerms(_debtId, _packedDebtTerms);
    }

    /**
     * Updates the packed debt terms for a given debt ID.
     *
     * @param _debtId The debt ID to update the packed debt terms.
     *
     * See {DebtTermIndexer._updateDebtTerms}.
     */
    function _updateDebtTerms(
        uint256 _debtId,
        bytes32 _packedDebtTerms
    ) internal {
        __packedDebtTerms._updateDebtTerms(_debtId, _packedDebtTerms);
    }

    /**
     * Returns the loan state for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan state for.
     *
     * See {DebtTermIndexer._loanState}.
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
     * See {DebtTermIndexer._firInterval}.
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
     * See {DebtTermIndexer._fixedInterestRate}.
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
     * See {DebtTermIndexer._isFixed}.
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
     * See {DebtTermIndexer._loanLastChecked}.
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
     * See {DebtTermIndexer._loanStart}.
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
     * See {DebtTermIndexer._loanDuration}.
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
     * See {DebtTermIndexer._loanCommital}.
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
     * See {DebtTermIndexer._loanClose}.
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
     * See {DebtTermIndexer._lenderRoyalties}.
     *
     * @return The lender royalties for the given debt ID.
     */
    function lenderRoyalties(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._lenderRoyalties(_debtId);
    }

    /**
     * Returns the active loan count of a given collateralized token.
     *
     * TODO: This is not used anywhere. It is also captured in the DebtMaps
     * database. Remove?
     *
     * @param _debtId The debt ID to return the active loan count for.
     *
     * See {DebtTermIndexer._activeLoanCount}.
     *
     * @return The active loan count for the given debt ID.
     */
    function activeLoanCount(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._activeLoanCount(_debtId);
    }

    function checkCommitted(uint256 _debtId) public view returns (bool) {
        return __packedDebtTerms._checkCommitted(_debtId);
    }
}
