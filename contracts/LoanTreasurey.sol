// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";

import "./domain/LoanContractFIRIntervals.sol";
import "./domain/LoanContractRoles.sol";
import "./domain/LoanContractStates.sol";

import "./interfaces/ILoanTreasurey.sol";
import "./access/TreasureyAccessController.sol";
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
    mapping(uint256 debtId => uint256) private __debtSaleNonces;
    mapping(uint256 debtId => uint256) private __sponsorshipSaleNonces;

    constructor() TreasureyAccessController() {}

    modifier debtUpdater(uint256 _debtId) {
        updateDebt(_debtId);
        if (!_loanManager.checkLoanExpired(_debtId)) {
            _;
            _loanManager.updateLoanState(_debtId);
        }
    }

    modifier onlyActiveLoan(uint256 _debtId) {
        _loanManager.verifyLoanActive(_debtId);
        _;
    }

    function getDebtSaleNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return
            getDebtSaleNonce(
                _loanContract.getCollateralDebtId(
                    _collateralAddress,
                    _collateralId
                )
            );
    }

    function getDebtSaleNonce(uint256 _debtId) public view returns (uint256) {
        return __debtSaleNonces[_debtId] + 1;
    }

    function getSponsorshipSaleNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return
            getSponsorshipSaleNonce(
                _loanContract.getCollateralDebtId(
                    _collateralAddress,
                    _collateralId
                )
            );
    }

    function getSponsorshipSaleNonce(
        uint256 _debtId
    ) public view returns (uint256) {
        return __sponsorshipSaleNonces[_debtId] + 1;
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

        if (!_anzaToken.checkBorrowerOf(_borrower, _debtId))
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

    function withdrawCollateral(uint256 _debtId) external returns (bool) {
        return _loanCollateralVault.withdraw(msg.sender, _debtId);
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
        returns (bool _results)
    {
        // Increment nonce
        ++__debtSaleNonces[_debtId];

        uint256 _balance = _loanContract.debtBalanceOf(_debtId);
        uint256 _payment = msg.value;

        // Transfer collateral
        if (_payment >= _balance) {
            _depositPayment(_purchaser, _debtId, _balance);

            _loanCollateralVault.withdraw(_purchaser, _debtId);

            withdrawableBalance[_borrower] += _payment - _balance;
        }
        // Transfer debt
        else {
            _depositPayment(_purchaser, _debtId, _payment);

            _anzaToken.anzaTransferFrom(_borrower, _purchaser, _debtId, "");
        }

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
        address _borrower,
        address _purchaser
    )
        external
        payable
        onlyRole(_DEBT_STOREFRONT_)
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        returns (bool _results)
    {
        // Increment nonce
        ++__sponsorshipSaleNonces[_debtId];

        uint256 _balance = _loanContract.debtBalanceOf(_debtId);
        uint256 _payment = msg.value;

        // Transfer collateral
        if (_payment >= _balance) {
            _depositPayment(_purchaser, _debtId, _balance);

            _loanCollateralVault.withdraw(_purchaser, _debtId);

            withdrawableBalance[_borrower] += _payment - _balance;
        }
        // Transfer debt
        else {
            _depositPayment(_purchaser, _debtId, _payment);

            _anzaToken.anzaTransferFrom(_borrower, _purchaser, _debtId, "");
        }

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
        address _lender = _anzaToken.lenderOf(_debtId);
        uint256 _balance = _anzaToken.balanceOf(_lender, _debtId * 2);

        // Update lender's withdrawable balance
        if (_balance > _payment) {
            withdrawableBalance[_lender] += _payment;

            // Burn ALC debt token
            _anzaToken.burn(_lender, _debtId * 2, _payment);
        } else {
            withdrawableBalance[_lender] += _balance;
            withdrawableBalance[_payer] += _payment - _balance;

            // Burn ALC debt token
            _anzaToken.burn(_lender, _debtId * 2, _balance);
        }

        // Conditionally burn replica
        if (!_loanManager.checkLoanActive(_debtId)) {
            _anzaToken.burnBorrowerToken(_debtId);
        }
    }
}
