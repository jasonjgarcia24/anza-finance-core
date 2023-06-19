// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {StdLoanErrors} from "@custom-errors/StdLoanErrors.sol";

import {IDebtBook} from "@lending-databases/interfaces/IDebtBook.sol";
import {ICollateralVault} from "@lending-interfaces/ICollateralVault.sol";
import {DebtBookAccessController} from "@lending-access/DebtBookAccessController.sol";

/**
 * @title DebtBook
 * @author jjgarcia.eth
 * @notice A contract for managing debt.
 */
abstract contract DebtBook is IDebtBook, DebtBookAccessController {
    // Count of total inactive/active debts
    uint256 public totalDebts;

    // Mapping from collateral to debt
    mapping(address collateralAddress => mapping(uint256 collateralId => DebtMap[]))
        private __debtMaps;

    constructor() DebtBookAccessController() {}

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(DebtBookAccessController) returns (bool) {
        return
            _interfaceId == type(IDebtBook).interfaceId ||
            DebtBookAccessController.supportsInterface(_interfaceId);
    }

    /* ------------------------------------------------ *
     *                      Getters                     *
     * ------------------------------------------------ */
    /**
     * Returns the total debt balance for a debt ID.
     *
     * @param _debtId The debt ID to find the balance for.
     *
     * @return The total debt balance for the debt ID.
     */
    function debtBalance(uint256 _debtId) public view returns (uint256) {
        return _anzaToken.totalSupply(_anzaToken.lenderTokenId(_debtId));
    }

    /**
     * Returns the debt balance for a lender for a given debt ID.
     *
     * @param _debtId The debt ID to find the balance for.
     *
     * @return The debt balance for the lender for the debt ID.
     */
    function lenderDebtBalance(uint256 _debtId) public view returns (uint256) {
        return
            _anzaToken.balanceOf(
                _anzaToken.lenderOf(_debtId),
                _anzaToken.lenderTokenId(_debtId)
            );
    }

    /**
     * Returns the debt balance for a borrower for a given debt ID.
     *
     * @param _debtId The debt ID to find the balance for.
     *
     * @return The debt balance for the borrower for the debt ID.
     */
    function borrowerDebtBalance(
        uint256 _debtId
    ) public view returns (uint256) {
        return
            _anzaToken.balanceOf(
                _anzaToken.borrowerOf(_debtId),
                _anzaToken.borrowerTokenId(_debtId)
            );
    }

    /**
     * Returns the full count of the debt balance for a given collateral
     * token (i.e. the number of ADT held by lenders for this collateral).
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return _debtBalance The full count of the debt balance for the collateral.
     */
    function collateralDebtBalance(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256 _debtBalance) {
        DebtMap[] memory _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        for (uint256 i; i < _debtMaps.length; ) {
            console.log("debtId: %s", _debtMaps[i].debtId);

            _debtBalance += _anzaToken.totalSupply(
                _anzaToken.lenderTokenId(_debtMaps[i].debtId)
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Returns the number of debt maps for a collateral.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return The number of debt maps for the collateral.
     */
    function collateralDebtCount(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256) {
        return __debtMaps[_collateralAddress][_collateralId].length;
    }

    function collateralDebtAt(
        uint256 _debtId,
        uint256 _index
    ) public view returns (uint256, uint256) {
        ICollateralVault.Collateral memory _collateral = _collateralVault
            .getCollateral(_debtId);

        return
            collateralDebtAt(
                _collateral.collateralAddress,
                _collateral.collateralId,
                _index
            );
    }

    /**
     * Returns the debt map for a collateral at a given index.
     *
     * @notice If the index is type(uint256).max, the latest debt map is returned.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     * @param _index The index of the debt map to return.
     *
     * Reverts if the index is out of bounds and not type(uint256).max.
     *
     * @return The debt map at the given index.
     */
    function collateralDebtAt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _index
    ) public view returns (uint256, uint256) {
        DebtMap[] memory _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // If no debt to collateral, revert
        if (_debtMaps.length == 0) revert StdLoanErrors.InvalidCollateral();

        // Allow an easy way to return the latest debt
        if (_index == type(uint256).max)
            return (
                _debtMaps[_debtMaps.length - 1].debtId,
                _debtMaps[_debtMaps.length - 1].collateralNonce
            );

        // If index is out of bounds, revert
        if (_debtMaps.length <= _index)
            revert StdLoanErrors.InvalidCollateral();

        // Return the debt at the index
        return (_debtMaps[_index].debtId, _debtMaps[_index].collateralNonce);
    }

    /**
     * Returns the nonce of the next loan contract for a collateral.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return The nonce of the next loan contract for a collateral.
     */
    function collateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256) {
        if (__debtMaps[_collateralAddress][_collateralId].length == 0) return 1;

        (, uint256 _collateralNonce) = collateralDebtAt(
            _collateralAddress,
            _collateralId,
            type(uint256).max
        );

        return _collateralNonce + 1;
    }

    /* ------------------------------------------------ *
     *                      Setters                     *
     * ------------------------------------------------ */

    /**
     * Writes a debt to the database.
     *
     * @notice This function will clear all previous debts for the collateral.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return _debtMapsLength The collateral nonce for the debt. Note, this will
     * always be 1 for this write function.
     * @return _collateralNonce The collateral nonce for the debt.
     */
    function _writeDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) internal returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        // Set debt
        DebtMap[] storage _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // Record new collateral nonce
        _collateralNonce = _debtMaps.length == 0
            ? 1
            : _debtMaps[_debtMaps.length - 1].collateralNonce + 1;

        // Clear previous debts
        delete __debtMaps[_collateralAddress][_collateralId];

        // Set debt fields
        _debtMaps.push(
            DebtMap({debtId: ++totalDebts, collateralNonce: _collateralNonce})
        );

        return (1, _collateralNonce);
    }

    /**
     * Appends a debt to the database.
     *
     * @notice This function will not clear previous debts for the collateral.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return _debtMapsLength The new length of the debt map array.
     * @return _collateralNonce The collateral nonce for the debt.
     */
    function _appendDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) internal returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        // Set debt
        DebtMap[] storage _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // Record new collateral nonce
        _collateralNonce = _debtMaps[_debtMaps.length - 1].collateralNonce + 1;

        // Set debt fields
        _debtMaps.push(
            DebtMap({debtId: ++totalDebts, collateralNonce: _collateralNonce})
        );

        return (_debtMaps.length, _collateralNonce);
    }
}
