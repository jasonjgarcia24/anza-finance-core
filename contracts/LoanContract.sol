// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LoanManager.sol";
import "./utils/TypeUtils.sol";
import {LoanNotary} from "./LoanNotary.sol";
import {ILoanContract} from "./interfaces/ILoanContract.sol";
import {ICollateralVault} from "./interfaces/ICollateralVault.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract LoanContract is ILoanContract, LoanManager, LoanNotary, TypeUtils {
    // Count of total inactive/active debts
    uint256 public totalDebts;

    // Mapping from collateral to debt ID
    mapping(address collateralAddress => mapping(uint256 collateralId => Debt))
        public debts;
    mapping(uint256 childDebtId => Debt parentDebtId) public debtIdBranch;

    constructor() LoanManager() LoanNotary("LoanContract", "0") {}

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(AccessControl) returns (bool) {
        return
            _interfaceId == 0xb7c3c5ea || // ILoanContract
            _interfaceId == 0x4a23979d || // ILoanManager
            _interfaceId == 0xf83e032d || // ILoanCodec
            AccessControl.supportsInterface(_interfaceId);
    }

    /*
     * This should report back only the total debt tokens, not the ALC NFTs.
     * TODO: Test
     */
    function debtBalanceOf(uint256 _debtId) public view returns (uint256) {
        return _anzaToken.totalSupply(_debtId * 2);
    }

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debts[_collateralAddress][_collateralId].collateralNonce + 1;
    }

    function getCollateralDebtId(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debts[_collateralAddress][_collateralId].debtId;
    }

    function getActiveLoanIndex(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debts[_collateralAddress][_collateralId].activeLoanIndex;
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
        uint64 _now = _toUint64(block.timestamp);
        uint256 _principal = msg.value;
        _validateLoanTerms(_contractTerms, _now, _principal);

        // Set debt
        Debt storage _debt = debts[_collateralAddress][_collateralId];

        // Set loan fields
        _debt.debtId = ++totalDebts;
        ++_debt.activeLoanIndex;
        ++_debt.collateralNonce;

        // Verify borrower participation
        IERC721Metadata _collateralToken = IERC721Metadata(_collateralAddress);

        address _borrower = _getBorrower(
            _collateralId,
            ContractParams({
                principal: _principal,
                contractTerms: _contractTerms,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                collateralNonce: _debt.collateralNonce
            }),
            _borrowerSignature,
            _collateralToken.ownerOf
        );

        // Add debt to database
        __setLoanAgreement(_now, 0, _contractTerms);

        // The collateral ID and address will be mapped within
        // the loan collateral vault to the debt ID.
        _collateralToken.safeTransferFrom(
            _borrower,
            _collateralVault,
            _collateralId,
            abi.encodePacked(totalDebts)
        );

        // Transfer funds to borrower's account in treasurey
        (bool _success, ) = _loanTreasurer.call{value: _principal}(
            abi.encodeWithSignature("depositFunds(address)", _borrower)
        );
        if (!_success) revert FailedFundsTransfer();

        // Mint debt ALC debt tokens for lender
        _anzaToken.mint(
            msg.sender,
            totalDebts * 2,
            _principal,
            _collateralToken.tokenURI(_collateralId),
            abi.encodePacked(_borrower)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateralAddress,
            _collateralId,
            totalDebts,
            0
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
        uint64 _now = _toUint64(block.timestamp);
        uint256 _principal = msg.value;
        _validateLoanTerms(_contractTerms, _now, _principal);

        // Get collateral from vault
        ICollateralVault _loanCollateralVault = ICollateralVault(
            _collateralVault
        );
        ICollateralVault.Collateral memory _collateral = _loanCollateralVault
            .getCollateral(_debtId);

        // Set debt
        Debt storage _debt = debts[_collateral.collateralAddress][
            _collateral.collateralId
        ];

        // Map the child loan to the parent
        debtIdBranch[_debt.debtId] = _debt;

        // Set child loan fields
        _debt.debtId = ++totalDebts;
        ++_debt.activeLoanIndex;
        ++_debt.collateralNonce;

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
                collateralNonce: _debt.collateralNonce
            }),
            _borrowerSignature,
            _anzaToken.borrowerOf
        );

        // Add debt to database
        __setLoanAgreement(_now, _debt.activeLoanIndex, _contractTerms);

        // Store collateral-debtId mapping in vault
        _loanCollateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts
        );

        // Replace or reduce previous debt. Any excess funds will
        // be available for withdrawal in the treasurey.
        uint256 _balance = debtBalanceOf(_debtId);
        (bool _success, ) = _loanTreasurer.call{
            value: _principal >= _balance ? _balance : _principal
        }(
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
            totalDebts * 2,
            _principal,
            _collateralToken.tokenURI(_collateral.collateralId),
            abi.encodePacked(_borrower)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debt.activeLoanIndex
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
        // Not necessary since the terms are existing and have already
        // been validated.
        uint64 _now = _toUint64(block.timestamp);
        uint256 _principal = msg.value;

        // Get collateral from vault
        ICollateralVault _loanCollateralVault = ICollateralVault(
            _collateralVault
        );
        ICollateralVault.Collateral memory _collateral = _loanCollateralVault
            .getCollateral(_debtId);

        // Set debt
        Debt storage _debt = debts[_collateral.collateralAddress][
            _collateral.collateralId
        ];

        // Map the child loan to the parent
        debtIdBranch[_debt.debtId] = _debt;

        // Set child loan fields
        _debt.debtId = ++totalDebts;
        ++_debt.activeLoanIndex;
        ++_debt.collateralNonce;

        // Add debt to database
        __setLoanAgreement(_now, _debt.activeLoanIndex, getDebtTerms(_debtId));

        // Store collateral-debtId mapping in vault
        _loanCollateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts
        );

        // Replace or reduce previous debt. Any excess funds will
        // be available for withdrawal in the treasurey.
        uint256 _balance = debtBalanceOf(_debtId);
        (bool _success, ) = _loanTreasurer.call{
            value: _principal >= _balance ? _balance : _principal
        }(
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
            totalDebts * 2,
            _principal,
            IERC721Metadata(_collateral.collateralAddress).tokenURI(
                _collateral.collateralId
            ),
            abi.encodePacked(_borrower)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debt.activeLoanIndex
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
