// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../lib/forge-std/src/console.sol";

import "./domain/LoanContractFIRIntervals.sol";
import "./domain/LoanContractRoles.sol";
import "./domain/LoanContractStates.sol";
import "./domain/AnzaTokenTransferTypes.sol";

import {ILoanTreasurey} from "./interfaces/ILoanTreasurey.sol";
import {ICollateralVault} from "./interfaces/ICollateralVault.sol";
import {TreasureyAccessController} from "./access/TreasureyAccessController.sol";
import {LibLoanContractInterest as Interest} from "./libraries/LibLoanContract.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LoanTreasurey is
    ILoanTreasurey,
    TreasureyAccessController,
    ReentrancyGuard
{
    using Address for address payable;

    uint256 public poolBalance;
    mapping(address account => uint256) public withdrawableBalance;

    constructor() TreasureyAccessController() {}

    modifier debtUpdater(uint256 _debtId) {
        updateDebt(_debtId);
        if (
            !_loanManager.checkLoanExpired(_debtId) &&
            !_loanManager.checkLoanClosed(_debtId)
        ) {
            _;
            _loanManager.updateLoanState(_debtId);
        }
    }

    modifier onlyActiveLoan(uint256 _debtId) {
        _loanManager.verifyLoanActive(_debtId);
        _;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(TreasureyAccessController) returns (bool) {
        return
            _interfaceId == type(ILoanTreasurey).interfaceId ||
            TreasureyAccessController.supportsInterface(_interfaceId);
    }

    function depositFunds(
        address _account
    ) external payable onlyRole(_LOAN_CONTRACT_) nonReentrant {
        withdrawableBalance[_account] += msg.value;

        emit Deposited(type(uint256).max, _account, msg.value);
    }

    function sponsorPayment(
        address _sponsor,
        uint256 _debtId
    ) external payable onlyActiveLoan(_debtId) debtUpdater(_debtId) {
        uint256 _payment = msg.value;

        // Overpayments checked when burning lender debt tokens.
        // Therefore, no need to check here.
        if (_payment == 0) revert InvalidFundsTransfer();

        _depositPayment(_sponsor, _debtId, _payment);

        emit Deposited(_debtId, _sponsor, _payment);
    }

    function depositPayment(
        uint256 _debtId
    ) external payable onlyActiveLoan(_debtId) debtUpdater(_debtId) {
        address _borrower = msg.sender;
        uint256 _payment = msg.value;

        // Overpayments checked when burning lender debt tokens.
        // Therefore, no need to check here.
        if (_payment == 0) revert InvalidFundsTransfer();

        if (_anzaToken.borrowerOf(_debtId) != _borrower)
            revert InvalidParticipant();

        _depositPayment(_borrower, _debtId, _payment);

        emit Deposited(_debtId, _borrower, _payment);
    }

    function withdrawFromBalance(
        uint256 _amount
    ) external nonReentrant returns (bool) {
        address _payee = msg.sender;

        if (_amount == 0) revert InvalidFundsTransfer();

        // Update lender's withdrawable balance. Will revert
        // with arithmetic underflow should amount be greater
        // than withdrawable balance.
        withdrawableBalance[_payee] -= _amount;

        // Transfer payment funds to lender
        (bool _success, ) = _payee.call{value: _amount}("");
        require(_success);

        emit Withdrawn(_payee, _amount);

        return _success;
    }

    function withdrawCollateral(
        uint256 _debtId
    ) external nonReentrant returns (bool) {
        return _collateralVault.withdraw(msg.sender, _debtId);
    }

    /*
     * A transfer of debt responsibilities of the current borrower to the
     * purchaser.
     *
     * This method is straight forward due to the state of the borrower account
     * only being tied to the borrower role for the given Anza Token ID.
     * Therefore, no change is made to the original loan contract nor is an
     * updated debt ID necessary.
     *
     * Scenario #1:
     *   Should the payment cover the cost of the debt, the payment less
     *   the excess funds is used to close out the loan, the excess funds
     *   from the payment, if any, will be transferred to the borrower's
     *   account and the purchaser will be able to withdraw the collateral
     *   to their account. In this case, the borrower will forfeit the
     *   collateral to the purchaser at the debt's value.
     *
     * Scenario #2:
     *   Should the payment not cover the entirety of the debt, the
     *   payment is applied directly to the loan, the borrower's withdrawable
     *   balance remains unchanged, and the purchaser will become the
     *   loan's borrower. In this case, the borrower will forfeit the collateral
     *   to the purchaser at a lesser cost than the debt's value.
     *
     * Requirements:
     *  - Only the debt storefront can execute this method.
     *  - The debt must be active.
     *  - The payment must be greater than zero and less than or equal to the
     *    debt's balance.
     *  - The debt's collateral must be in the vault.
     */
    function executeDebtPurchase(
        uint256 _debtId,
        address _borrower,
        address _purchaser
    )
        external
        payable
        onlyRole(_DEBT_STOREFRONT_)
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        nonReentrant
        returns (bool _results)
    {
        uint256 _debtBalance = _loanContract.debtBalance(_debtId);
        uint256 _payment = msg.value;

        // Transfer collateral
        if (_payment >= _debtBalance) {
            _depositPayment(_purchaser, _debtId, _debtBalance);

            _collateralVault.withdraw(_purchaser, _debtId);

            withdrawableBalance[_borrower] += _payment - _debtBalance;
        }
        // Transfer debt
        else {
            _depositPayment(_purchaser, _debtId, _payment);

            _anzaToken.safeTransferFrom(
                _borrower,
                _purchaser,
                _debtId,
                _payment,
                abi.encodePacked(_DEBT_TRANSFER_)
            );
        }

        _results = true;
    }

    function executeRefinancePurchase(
        uint256 _debtId,
        address _borrower,
        address _purchaser,
        bytes32 _contracTerms
    )
        external
        payable
        onlyRole(_DEBT_STOREFRONT_)
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        nonReentrant
        returns (bool _results)
    {
        // Create loan contract for new lender
        (bool _success, ) = address(_loanContract).call{value: msg.value}(
            abi.encodeWithSignature(
                "initLoanContract(uint256,address,address,bytes32)",
                _debtId,
                _borrower,
                _purchaser,
                _contracTerms
            )
        );
        if (!_success) revert FailedPurchase();

        _results = true;
    }

    /*
     * A full transfer of debt responsibilities of the current borrower
     * to the purchaser.
     *
     * Scenario #1:
     *   Should the payment cover the cost of the debt, the payment less
     *   the excess funds is used to close out the loan, the excess funds
     *   from the payment, if any, will be transferred to the borrower's
     *   account and the purchaser will be able to withdraw the collateral
     *   to their account.
     *
     * Scenario #2:
     *   Should the payment not cover the entirety of the debt, the
     *   payment is applied directly to the loan, the borrower's withdrawable
     *   balance remains unchanged, and the purchaser will become the
     *   loan's borrower.
     */
    function executeSponsorshipPurchase(
        uint256 _debtId,
        address /* _seller */,
        address _purchaser
    )
        external
        payable
        onlyRole(_DEBT_STOREFRONT_)
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        nonReentrant
        returns (bool _results)
    {
        // Create loan contract for new lender
        (bool _success, ) = address(_loanContract).call{value: msg.value}(
            abi.encodeWithSignature(
                "initLoanContract(uint256,address,address)",
                _debtId,
                _anzaToken.borrowerOf(_debtId),
                _purchaser
            )
        );
        if (!_success) revert FailedPurchase();

        _results = true;
    }

    // TODO: Need to revisit to ensure accuracy at larger total debt values
    // (e.g. 10000 * 10**18).
    function updateDebt(uint256 _debtId) public {
        uint256 _prevCheck = _loanCodec.loanLastChecked(_debtId);

        // Find time intervals passed
        _loanManager.updateLoanState(_debtId);

        uint256 _firIntervals = _loanCodec.totalFirIntervals(
            _debtId,
            _loanCodec.loanLastChecked(_debtId) - _prevCheck
        );

        // Update debt
        if (_firIntervals > 0) {
            uint256 _totalDebt = _anzaToken.totalSupply(_debtId * 2);

            uint256 _updatedDebt = Interest.compoundWithTopoff(
                _totalDebt,
                _loanCodec.fixedInterestRate(_debtId),
                _firIntervals
            );

            _anzaToken.mint(_debtId, _updatedDebt - _totalDebt);
        }
    }

    function _depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) internal {
        if (_payment == 0) revert InvalidFundsTransfer();

        address _lender = _anzaToken.lenderOf(_debtId);
        uint256 _balance = _anzaToken.balanceOf(_lender, _debtId * 2);

        // Update lender's withdrawable balance
        if (_balance > _payment) {
            withdrawableBalance[_lender] += _payment;

            // Burn ADT of lender
            _anzaToken.burnLenderToken(_debtId, _payment);
        } else {
            withdrawableBalance[_lender] += _balance;
            withdrawableBalance[_payer] += _payment - _balance;

            // Burn ADT of lender
            _anzaToken.burnLenderToken(_debtId, _balance);

            // Burn ADT of borrower
            try _anzaToken.burnBorrowerToken(_debtId) {} catch {}
        }
    }
}
