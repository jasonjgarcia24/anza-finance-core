// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../lib/forge-std/src/console.sol";

import {ILoanContract} from "./interfaces/ILoanContract.sol";
import {LoanManager, ICollateralVault, ManagerAccessController, _TREASURER_} from "./LoanManager.sol";
import {LoanNotary} from "./LoanNotary.sol";
import {TypeUtils} from "./utils/TypeUtils.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract LoanContract is ILoanContract, LoanManager, LoanNotary, TypeUtils {
    // Count of total inactive/active debts
    uint256 public totalDebts;

    // Mapping from collateral to debt ID
    mapping(address collateralAddress => mapping(uint256 collateralId => DebtMap[]))
        private __debtMaps;

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
    ) public view returns (DebtMap memory) {
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
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     * @param _index The index of the debt map to return.
     *
     * @return The debt map at the given index.
     */
    function collateralDebtAt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _index
    ) public view returns (DebtMap memory) {
        DebtMap[] memory _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // If no debt to collateral, revert
        if (_debtMaps.length == 0) revert InvalidCollateral();

        // Allow an easy way to return the latest debt
        if (_index == type(uint256).max) return _debtMaps[_debtMaps.length - 1];

        // If index is out of bounds, revert
        if (_debtMaps.length < _index) revert InvalidIndex();

        // Return the debt at the index
        return _debtMaps[_index];
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

        return
            collateralDebtAt(
                _collateralAddress,
                _collateralId,
                type(uint256).max
            ).collateralNonce + 1;
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
        DebtMap[] storage _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // Record new collateral nonce
        uint256 _collateralNonce = _debtMaps.length == 0
            ? 1
            : _debtMaps[_debtMaps.length - 1].collateralNonce + 1;

        // Clear previous debts
        delete __debtMaps[_collateralAddress][_collateralId];

        // Set debt fields
        _debtMaps.push(
            DebtMap({debtId: ++totalDebts, collateralNonce: _collateralNonce})
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
        __setLoanAgreement(_toUint64(block.timestamp), 1, _contractTerms);

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
        DebtMap[] storage _debtMaps = __debtMaps[_collateral.collateralAddress][
            _collateral.collateralId
        ];

        _debtMaps.push(
            DebtMap({
                debtId: ++totalDebts,
                collateralNonce: _debtMaps[_debtMaps.length - 1]
                    .collateralNonce + 1
            })
        );

        // Verify borrower participation
        IERC721Metadata _collateralToken = IERC721Metadata(
            _collateral.collateralAddress
        );

        // Add debt to database
        __setLoanAgreement(
            _toUint64(block.timestamp),
            _debtMaps.length,
            _contractTerms
        );

        // Store collateral-debtId mapping in vault
        _collateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMaps.length
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
            _debtMaps.length
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
        DebtMap[] storage _debtMaps = __debtMaps[_collateral.collateralAddress][
            _collateral.collateralId
        ];

        // Set debt fields
        _debtMaps.push(
            DebtMap({
                debtId: ++totalDebts,
                collateralNonce: _debtMaps[_debtMaps.length - 1]
                    .collateralNonce + 1
            })
        );

        // Add debt to database
        __setLoanAgreement(
            _toUint64(block.timestamp),
            _debtMaps.length,
            getDebtTerms(_debtId)
        );

        // Store collateral-debtId mapping in vault
        _collateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMaps.length
        );

        // Record balance for redistribution of debt.
        // @note: This is necessary since the debt will be reduced
        // by the sponsorPayment function.
        uint256 _balance = _anzaToken.balanceOf(
            _anzaToken.lenderOf(_debtId),
            _anzaToken.lenderTokenId(_debtId)
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
            _principal >= _balance ? _balance : _principal,
            abi.encode(address(_borrower), _debtId)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMaps.length
        );
    }

    function __setLoanAgreement(
        uint64 _now,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) private {
        if (_activeLoanIndex > maxRefinances) revert ExceededRefinanceLimit();

        _setLoanAgreement(_now, totalDebts, _activeLoanIndex, _contractTerms);
    }
}
