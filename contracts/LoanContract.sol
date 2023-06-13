// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_TREASURER_} from "@lending-constants/LoanContractRoles.sol";
import {InvalidCollateral} from "@custom-errors/StdLoanErrors.sol";
import {FailedFundsTransfer, ExceededRefinanceLimit} from "@custom-errors/StdMonetaryErrors.sol";

import {ILoanContract} from "@lending-interfaces/ILoanContract.sol";
import {ICollateralVault} from "@lending-interfaces/ICollateralVault.sol";
import {LoanManager} from "./LoanManager.sol";
import {LoanNotary} from "./LoanNotary.sol";
import {TypeUtils} from "./utils/TypeUtils.sol";

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract LoanContract is ILoanContract, LoanManager, LoanNotary, TypeUtils {
    constructor() LoanManager() LoanNotary("LoanContract", "0") {}

    /**
     * Returns the support status of an interface.
     *
     * @param _interfaceId The interface ID to check for support.
     *
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(LoanManager, LoanNotary) returns (bool) {
        return
            _interfaceId == type(ILoanContract).interfaceId ||
            LoanManager.supportsInterface(_interfaceId) ||
            LoanNotary.supportsInterface(_interfaceId);
    }

    /**
     * Initialize a loan contract for an uncollateralized ERC721 token.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     * @param _contractTerms The loan contract terms.
     * @param _borrowerSignature The borrower's signature of the loan contract
     * terms.
     *
     * @dev The `_contractTerms` parameter is a packed bytes32 array of the
     * following values:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   `isFixed` and `commital`
     *  > 008 - [20..27]   `loanCurrency`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     *
     * Emits a {LoanContractInitialized} event.
     */
    function initLoanContract(
        address _collateralAddress,
        uint256 _collateralId,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) external payable {
        // Validate loan terms
        uint256 _principal = msg.value;
        _validateLoanTerms(
            _contractTerms,
            _toUint64(block.timestamp),
            _principal
        );

        // Set debt
        (, uint256 _collateralNonce) = _writeDebt(
            _collateralAddress,
            _collateralId
        );

        // Verify borrower participation
        IERC721Metadata _collateralToken = IERC721Metadata(_collateralAddress);

        address _borrower = _getBorrower(
            _collateralId,
            ContractParams({
                principal: _principal,
                contractTerms: _contractTerms,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            }),
            _borrowerSignature,
            _collateralToken.ownerOf
        );

        // Add debt to database
        __sealLoanContract(_toUint64(block.timestamp), 1, _contractTerms);

        // The collateral ID and address will be mapped within
        // the loan collateral vault to the debt ID.
        _collateralToken.safeTransferFrom(
            _borrower,
            address(_collateralVault),
            _collateralId,
            abi.encodePacked(totalDebts)
        );

        // Transfer funds to borrower's account in treasurey
        (bool _success, ) = _loanTreasurerAddress.call{value: _principal}(
            abi.encodeWithSignature("depositFunds(address)", _borrower)
        );
        if (!_success) revert FailedFundsTransfer();

        // Mint debt ADT for lender
        string memory _collateralURI = _collateralToken.tokenURI(_collateralId);

        _anzaToken.mint(
            msg.sender,
            totalDebts,
            _principal,
            _collateralURI,
            abi.encodePacked(_borrower)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateralAddress,
            _collateralId,
            totalDebts,
            1
        );
    }

    /**
     * Refinance fractions of debt with a new loan. This will alter and create
     * a new debt agreement for the collateralized ERC721 token.
     *
     * @dev The call stack of this function is:
     * > AnzaDebtStorefront:buyRefinance(uint256,uint256,{uint256},bytes)
     * > LoanTreasurey:executeRefinancePurchase(uint256,address,address,bytes32)
     *
     * @notice This function does not verify the loan contract with the
     * borrower. It should never be used to alter existing contract terms
     * and shall only be callable by the treasurer. It is required that the
     * treasurer verifies the loan contract with the borrower before calling
     * this function.
     *
     * @param _debtId The ID of the debt to refinance.
     * @param _borrower The address of the borrower.
     * @param _lender The address of the new lender.
     * @param _contractTerms The new loan contract terms.
     *
     * @dev The `_contractTerms` parameter is a packed bytes32 array of the
     * following values:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   unused space
     *  > 128 - [20..147]  `principal`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     *
     * Emits a {LoanContractRefinanced} event.
     */
    function initLoanContract(
        uint256 _debtId,
        address _borrower,
        address _lender,
        bytes32 _contractTerms
    ) external payable onlyRole(_TREASURER_) {
        // Verify existing loan is in good standing
        if (checkLoanDefault(_debtId)) revert InvalidCollateral();

        // Validate loan terms
        uint256 _principal = msg.value;
        _validateLoanTerms(
            _contractTerms,
            _toUint64(block.timestamp),
            _principal
        );

        // Get collateral from vault
        ICollateralVault.Collateral memory _collateral = _collateralVault
            .getCollateral(_debtId);

        // Set debt
        (uint256 _debtMapLength, ) = _appendDebt(
            _collateral.collateralAddress,
            _collateral.collateralId
        );

        // Add debt to database
        __sealLoanContract(
            _toUint64(block.timestamp),
            _debtMapLength,
            _contractTerms
        );

        // Store collateral-debtId mapping in vault
        _collateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );

        // Replace or reduce previous debt. Any excess funds will
        // be available for withdrawal in the treasurey.
        (bool _success, ) = _loanTreasurerAddress.call{value: _principal}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _borrower,
                _debtId
            )
        );
        if (!_success) revert FailedFundsTransfer();

        // Mint debt ADT for lender.
        _anzaToken.mint(
            _lender,
            totalDebts,
            _principal,
            abi.encode(address(_borrower), _debtId)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );
    }

    /**
     * Transfer debt to a new lender. This will not alter existing loan terms.
     *
     * @dev The call stack of this function is:
     * > AnzaDebtStorefront:buySponsorship(uint256,uint256,{uint256},bytes)
     * > LoanTreasurey:executeSponsorshipPurchase(uint256,address)
     *
     * @notice This function does not verify the loan contract with the
     * borrower. It should never be used to alter existing contract terms
     * and shall only be callable by the treasurer. It is required that the
     * treasurer verifies the loan contract with the borrower before calling
     * this function.
     *
     * @param _debtId The ID of the debt to refinance.
     * @param _borrower The address of the borrower.
     * @param _lender The address of the new lender.
     *
     * @dev The `_contractTerms` parameter is a packed bytes32 array of the
     * following values:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   unused space
     *  > 128 - [20..147]  `principal`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     *
     * Emits a {LoanContractRefinanced} event.
     */
    function initLoanContract(
        uint256 _debtId,
        address _borrower,
        address _lender
    ) external payable onlyRole(_TREASURER_) {
        // Verify existing loan is in good standing
        if (checkLoanDefault(_debtId)) revert InvalidCollateral();

        // Validate loan terms
        // Unnecessary since the terms are existing and have already been
        // validated.
        uint256 _principal = msg.value;

        // Get collateral from vault
        ICollateralVault.Collateral memory _collateral = _collateralVault
            .getCollateral(_debtId);

        // Set debt
        (uint256 _debtMapLength, ) = _appendDebt(
            _collateral.collateralAddress,
            _collateral.collateralId
        );

        // Add debt to database
        __sealLoanContract(
            _toUint64(block.timestamp),
            _debtMapLength,
            getDebtTerms(_debtId)
        );

        // Store collateral-debtId mapping in vault
        _collateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );

        // Record balance for redistribution of debt.
        // @note: This is necessary since the debt will be reduced
        // by the sponsorPayment function.
        uint256 _balance = lenderDebtBalance(_debtId);

        // Replace or reduce previous debt. Any excess funds will
        // be available for withdrawal in the treasurey.
        (bool _success, ) = _loanTreasurerAddress.call{value: _principal}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _borrower,
                _debtId
            )
        );
        if (!_success) revert FailedFundsTransfer();

        // Mint debt ADT for lender.
        _anzaToken.mint(
            _lender,
            totalDebts,
            _principal >= _balance ? _balance : _principal,
            abi.encode(address(_borrower), _debtId)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );
    }

    /**
     * Seal a loan agreement between a borrower and lender.
     *
     * @dev This function is called by the initLoanContract functions when a loan
     * agreement is validated. Following the completion of this function, a new
     * deb will be added to the `__packedDebtTerms` mapping as specified within
     * LoanCodec.sol.
     *
     * @param _now The current timestamp.
     * @param _activeLoanIndex The index of the active loan.
     * @param _contractTerms The contract terms.
     *
     * @dev Reverts if the `_activeLoanIndex` exceeds the maximum refinances.
     */
    function __sealLoanContract(
        uint64 _now,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) private {
        if (_activeLoanIndex > maxRefinances) revert ExceededRefinanceLimit();

        _setLoanAgreement(_now, totalDebts, _activeLoanIndex, _contractTerms);
    }
}
