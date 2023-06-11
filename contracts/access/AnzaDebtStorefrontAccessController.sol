// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../../lib/forge-std/src/console.sol";

import {IAnzaDebtStorefrontAccessController} from "../interfaces/IAnzaDebtStorefrontAccessController.sol";
import {IAnzaTokenIndexer} from "../interfaces/IAnzaTokenIndexer.sol";
import {ILoanContract} from "../interfaces/ILoanContract.sol";
import {ILoanManager} from "../interfaces/ILoanManager.sol";
import {DebtNotary} from "../LoanNotary.sol";

abstract contract AnzaDebtStorefrontAccessController is
    IAnzaDebtStorefrontAccessController,
    DebtNotary
{
    address public immutable loanTreasurerAddress;

    IAnzaTokenIndexer immutable _anzaTokenIndexer;
    ILoanContract immutable _loanContract;
    ILoanManager immutable _loanManager;

    constructor(
        address _anzaTokenAddress,
        address _loanContractAddress,
        address _loanTreasurerAddress
    ) DebtNotary("AnzaDebtStorefront", "0") {
        _anzaTokenIndexer = IAnzaTokenIndexer(_anzaTokenAddress);
        _loanContract = ILoanContract(_loanContractAddress);
        _loanManager = ILoanManager(_loanContractAddress);

        loanTreasurerAddress = _loanTreasurerAddress;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId ==
            type(IAnzaDebtStorefrontAccessController).interfaceId ||
            DebtNotary.supportsInterface(_interfaceId);
    }

    /**
     * Returns the address of the AnzaTokenIndexer.
     */
    function anzaToken() public view returns (address) {
        return address(_anzaTokenIndexer);
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
     * Verifies the caller is the borrower of a given debt ID.
     *
     * @param _debtId The debt ID to verify.
     *
     * @dev Reverts if the caller is not the borrower of the debt ID.
     */
    function _verifySeller(uint256 _debtId) internal view {
        if (_anzaTokenIndexer.borrowerOf(_debtId) != msg.sender)
            revert InvalidParticipant();
    }
}
