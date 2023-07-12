// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {StdManagerErrors} from "@custom-errors/StdManagerErrors.sol";

import {IAnzaSponsorshipStorefrontAccessController} from "@markets-access/interfaces/IAnzaSponsorshipStorefrontAccessController.sol";
import {IAnzaTokenCatalog} from "@tokens-interfaces/IAnzaTokenCatalog.sol";
import {ILoanContract} from "@base/interfaces/ILoanContract.sol";
import {ILoanManager} from "@services-interfaces/ILoanManager.sol";
import {SponsorshipNotary} from "@services/LoanNotary.sol";

abstract contract AnzaSponsorshipStorefrontAccessController is
    IAnzaSponsorshipStorefrontAccessController,
    SponsorshipNotary
{
    address public immutable loanTreasurerAddress;

    IAnzaTokenCatalog immutable _anzaTokenCatalog;
    ILoanContract immutable _loanContract;
    ILoanManager immutable _loanManager;

    constructor(
        address _anzaTokenAddress,
        address _loanContractAddress,
        address _loanTreasurerAddress
    ) SponsorshipNotary("AnzaSponsorshipStorefront", "0", _anzaTokenAddress) {
        _anzaTokenCatalog = IAnzaTokenCatalog(_anzaTokenAddress);
        _loanContract = ILoanContract(_loanContractAddress);
        _loanManager = ILoanManager(_loanContractAddress);

        loanTreasurerAddress = _loanTreasurerAddress;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId ==
            type(IAnzaSponsorshipStorefrontAccessController).interfaceId ||
            SponsorshipNotary.supportsInterface(_interfaceId);
    }

    /**
     * Returns the address of the AnzaTokenCatalog.
     */
    function anzaToken() public view returns (address) {
        return address(_anzaTokenCatalog);
    }

    /**
     * Returns the address of the loan contract.
     */
    function loanContract() public view returns (address) {
        return address(_loanContract);
    }

    /**
     * Returns the address of the loan manager. This shall be the same as the
     * loan contract.
     */
    function loanManager() public view returns (address) {
        return address(_loanManager);
    }

    /**
     * Verifies the caller is the lender of a given debt ID.
     *
     * @param _debtId The debt ID to verify.
     *
     * @dev Reverts if the caller is not the lender of the debt ID.
     */
    function _verifySeller(uint256 _debtId) internal view {
        if (_anzaTokenCatalog.lenderOf(_debtId) != msg.sender)
            revert StdManagerErrors.InvalidParticipant();
    }
}
