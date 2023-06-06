// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../lib/forge-std/src/console.sol";

import {ILoanContract} from "./interfaces/ILoanContract.sol";
import {LoanManager, ICollateralVault, ManagerAccessController, _TREASURER_} from "./LoanManager.sol";
import {LoanNotary} from "./LoanNotary.sol";
import "./utils/TypeUtils.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract LoanContract is ILoanContract, LoanManager, LoanNotary, TypeUtils {
    // Count of total inactive/active debts
    uint256 public totalDebts;

    // Mapping from collateral to debt ID
    mapping(address collateralAddress => mapping(uint256 collateralId => DebtMap[]))
        public __debtMaps;

    constructor() LoanManager() LoanNotary("LoanContract", "0") {}

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(LoanManager, LoanNotary) returns (bool) {
        return
            _interfaceId == type(ILoanContract).interfaceId ||
            LoanManager.supportsInterface(_interfaceId) ||
            LoanNotary.supportsInterface(_interfaceId);
    }

    /*
     * This should report back only the total debt tokens, not the ALC NFTs.
     * TODO: Test
     */
    function debtBalance(uint256 _debtId) public view returns (uint256) {
        return _anzaToken.totalSupply(_anzaToken.lenderTokenId(_debtId));
    }

    function getCollateralDebtCount(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256) {
        return __debtMaps[_collateralAddress][_collateralId].length;
    }

    function getCollateralDebtAt(
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

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256) {
        if (__debtMaps[_collateralAddress][_collateralId].length == 0) return 1;

        return
            getCollateralDebtAt(
                _collateralAddress,
                _collateralId,
                type(uint256).max
            ).collateralNonce + 1;
    }

    /**
     * Input _contractTerms:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   `isFixed` and `commital`
     *  > 008 - [20..27]   `loanCurrency`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     */
    function initLoanContract(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
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

        // Mint debt ALC debt tokens for lender
        _anzaToken.mint(
            msg.sender,
            totalDebts,
            _principal,
            _collateralToken.tokenURI(_collateralId),
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
     * Input _contractTerms:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   unused space
     *  > 128 - [20..147]  `principal`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     */
    function initLoanContract(
        bytes32 _contractTerms,
        uint256 _debtId,
        bytes calldata _borrowerSignature
    ) external payable {
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

        // Set debt fields
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

        address _borrower = _getBorrower(
            _debtId,
            ContractParams({
                principal: _principal,
                contractTerms: _contractTerms,
                collateralAddress: _collateral.collateralAddress,
                collateralId: _collateral.collateralId,
                collateralNonce: _debtMaps[_debtMaps.length - 1].collateralNonce
            }),
            _borrowerSignature,
            _anzaToken.borrowerOf
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

        // Mint debt ALC debt tokens for lender.
        _anzaToken.mint(
            msg.sender,
            totalDebts,
            _principal,
            _collateralToken.tokenURI(_collateral.collateralId),
            abi.encodePacked(_borrower)
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
     * @notice This function does not verify the loan contract with the
     * borrower. It should never be used to alter existing contract terms
     * and shall only be callable by the treasurer.
     *
     * Input _contractTerms:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   unused space
     *  > 128 - [20..147]  `principal`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
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

        // Mint debt ALC debt tokens for lender.
        _anzaToken.mint(
            _lender,
            totalDebts,
            _principal >= _balance ? _balance : _principal,
            abi.encode(address(_borrower), _debtMaps[0].debtId)
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
