// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import "@lending-constants/LoanContractStates.sol";
import {StdVaultErrors} from "@custom-errors/StdVaultErrors.sol";

import {IAnzaToken} from "@tokens-interfaces/IAnzaToken.sol";
import {ICollateralVault} from "@services-interfaces/ICollateralVault.sol";
import {ILoanCodec} from "@services-interfaces/ILoanCodec.sol";
import {IDebtBook} from "@lending-databases/interfaces/IDebtBook.sol";
import {VaultAccessController} from "@lending-access/VaultAccessController.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CollateralVault is
    ICollateralVault,
    VaultAccessController,
    ERC721Holder
{
    uint256 public totalCollateral;
    mapping(uint256 debtId => Collateral) private __collaterals;

    constructor(
        address _anzaTokenAddress
    ) VaultAccessController(_anzaTokenAddress) {
        // This is necessary because the LoanContract
        // debtId starts at 1.
        __collaterals[0] = Collateral(
            0x000000000000000000000000000000000000D3ad,
            0,
            type(uint256).max
        );
    }

    modifier onlyUniqueDeposit(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) {
        if (!depositAllowed(_collateralAddress, _collateralId, _debtId))
            revert StdVaultErrors.UnallowedDeposit();
        _;
    }

    modifier onlyWithdrawAllowed(address _to, uint256 _debtId) {
        if (!withdrawAllowed(_to, _debtId))
            revert StdVaultErrors.UnallowedWithdrawal();
        _;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(VaultAccessController) returns (bool) {
        return
            _interfaceId == type(ICollateralVault).interfaceId ||
            VaultAccessController.supportsInterface(_interfaceId);
    }

    function getCollateral(
        uint256 _debtId
    ) external view returns (Collateral memory) {
        return __collaterals[_debtId];
    }

    function setCollateral(
        address _from,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) external onlyRole(_LOAN_CONTRACT_) {
        _record(
            _from,
            _collateralAddress,
            _collateralId,
            _debtId,
            _activeLoanIndex
        );
    }

    /**
     * Returns whether a token is allowed to be deposited as collateral or
     * stored as a reference to collateral.
     *
     * @param _collateralAddress The collateral token's contract address.
     * @param _collateralId The collateral token's ID.
     * @param _debtId The debt ID associated with the collateral.
     *
     * This checks two things:
     *   1. The collateral token is associated with the `_debtId`
     *      within the loan contract.
     *   2. No collateral token has not been previously deposited
     *      for this `_debtId`.
     */
    function depositAllowed(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) public view returns (bool) {
        try
            IDebtBook(_loanContract).collateralDebtAt(
                _collateralAddress,
                _collateralId,
                type(uint256).max
            )
        returns (uint256 _latestDebtId, uint256 /* _latestCollateralNonce */) {
            return _latestDebtId == _debtId;
        } catch (bytes memory) {
            return false;
        }
    }

    /**
     * Returns whether an address is allowed to withdraw their collateral.
     *
     * This checks two things:
     *   1. The loan state is paid in full.
     *   2. The recipient is the borrower.
     *
     * @param _to The destination address of the collateral.
     * @param _debtId The debt ID mapped to the collateral.
     */
    function withdrawAllowed(
        address _to,
        uint256 _debtId
    ) public view returns (bool) {
        Collateral memory _collateral = __collaterals[_debtId];

        return
            IDebtBook(_loanContract).collateralDebtBalance(
                _collateral.collateralAddress,
                _collateral.collateralId
            ) ==
            0 && // Is debt balance 0?
            IAnzaToken(anzaToken).borrowerOf(_debtId) == _to; // Is borrower?
    }

    /**
     * Conducts a collateral withdraw from the vault.
     *
     * @param _to The destination address of the collateral.
     * @param _debtId The debt ID mapped to the collateral.
     *
     * @dev This function is only callable by the LoanTreasurer.
     * @dev This function is only callable when the collateral is
     * withdrawable.
     *
     * Emits a {WithdrawnCollateral} event.
     *
     * @return {bool} Returns true if the collateral was successfully
     * withdrawn.
     */
    function withdraw(
        address _to,
        uint256 _debtId
    )
        external
        onlyRole(_TREASURER_)
        onlyWithdrawAllowed(_to, _debtId)
        returns (bool)
    {
        Collateral storage _collateral = __collaterals[_debtId];
        totalCollateral -= 1;

        // Transfer collateral to borrower
        IERC721(_collateral.collateralAddress).safeTransferFrom(
            address(this),
            _to,
            _collateral.collateralId,
            ""
        );

        emit WithdrawnCollateral(
            _to,
            _collateral.collateralAddress,
            _collateral.collateralId
        );

        return true;
    }

    /**
     * Whenever an {IERC721} `tokenId` token is transferred to this contract via
     * {IERC721-safeTransferFrom} by `operator` from `from`, this function is called.
     *
     * @param _from The address which previously owned the token.
     * @param _collateralId The token ID which is being transferred.
     * @param _data Additional data containing the debt ID.
     *
     * @dev This function is only callable by the LoanContract.
     *
     * @return The Solidity selector to confirm the token transfer.
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _collateralId,
        bytes memory _data
    ) public override returns (bytes4) {
        _checkRole(_LOAN_CONTRACT_, _operator);

        _record(
            _from,
            msg.sender,
            _collateralId,
            uint256(bytes32(_data)) /* debtId */,
            0
        );

        // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        return 0x150b7a02;
    }

    function _record(
        address _from,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) internal onlyUniqueDeposit(_collateralAddress, _collateralId, _debtId) {
        // Add collateral to inventory
        ++totalCollateral;

        __collaterals[_debtId] = Collateral(
            _collateralAddress,
            _collateralId,
            _activeLoanIndex
        );

        if (_activeLoanIndex == 0)
            emit DepositedCollateral(_from, _collateralAddress, _collateralId);
    }
}
