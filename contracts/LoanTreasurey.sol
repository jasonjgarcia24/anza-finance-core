// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "./domain/LoanContractFIRIntervals.sol";
import "./domain/LoanContractStates.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ILoanTreasurey.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanCodec.sol";
import "./interfaces/ILoanManager.sol";
import "./interfaces/ILoanCollateralVault.sol";
import "./interfaces/IAnzaToken.sol";
import {LibOfficerRoles as Roles, LibLoanContractInterest as Interest} from "./libraries/LibLoanContract.sol";

contract LoanTreasurey is ILoanTreasurey, AccessControl, ReentrancyGuard {
    using Address for address payable;

    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    ILoanContract private immutable __loanContract;
    ILoanCodec private immutable __loanCodec;
    ILoanManager private immutable __loanManager;
    ILoanCollateralVault private immutable __loanCollateralVault;
    IAnzaToken private immutable __anzaToken;
    uint256 public poolBalance;

    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    // Mapping from participant to withdrawable balance
    mapping(address => uint256) public withdrawableBalance;

    constructor(
        address _loanContract,
        address _loanCollateralVault,
        address _anzaToken
    ) {
        __loanContract = ILoanContract(_loanContract);
        __loanCodec = ILoanCodec(_loanContract);
        __loanManager = ILoanManager(_loanContract);
        __loanCollateralVault = ILoanCollateralVault(_loanCollateralVault);
        __anzaToken = IAnzaToken(_anzaToken);

        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._LOAN_CONTRACT_, Roles._ADMIN_);
        _setRoleAdmin(Roles._DEBT_STOREFRONT_, Roles._ADMIN_);
        _grantRole(Roles._ADMIN_, msg.sender);
        _grantRole(Roles._LOAN_CONTRACT_, _loanContract);
    }

    modifier debtUpdater(uint256 _debtId) {
        updateDebt(_debtId);
        if (!__loanManager.checkLoanExpired(_debtId)) {
            _;
            __loanManager.updateLoanState(_debtId);
        }
    }

    modifier onlyActiveLoan(uint256 _debtId) {
        __loanManager.verifyLoanActive(_debtId);
        _;
    }

    function loanContract() external view returns (address) {
        return address(__loanManager);
    }

    function loanCollateralVault() external view returns (address) {
        return address(__loanCollateralVault);
    }

    function anzaToken() external view returns (address) {
        return address(__anzaToken);
    }

    function getDebtBalanceOf(uint256 _debtId) external view returns (uint256) {
        return __anzaToken.totalSupply(_debtId * 2);
    }

    function depositFunds(
        address _account
    ) external payable onlyRole(Roles._LOAN_CONTRACT_) nonReentrant {
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

        if (!__anzaToken.checkBorrowerOf(_borrower, _debtId))
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
        return __loanCollateralVault.withdraw(msg.sender, _debtId);
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
        onlyRole(Roles._DEBT_STOREFRONT_)
        onlyActiveLoan(_debtId)
        debtUpdater(_debtId)
        returns (bool _results)
    {
        uint256 _balance = __loanContract.debtBalanceOf(_debtId);
        uint256 _payment = msg.value;

        // Transfer collateral
        if (_payment >= _balance) {
            _depositPayment(_purchaser, _debtId, _balance);

            __loanCollateralVault.withdraw(_purchaser, _debtId);

            withdrawableBalance[_borrower] += _payment - _balance;
        }
        // Transfer debt
        else {
            _depositPayment(_purchaser, _debtId, _payment);

            __anzaToken.anzaTransferFrom(_borrower, _purchaser, _debtId, "");
        }

        _results = true;
    }

    // TODO: Need to revisit to ensure accuracy at larger total debt values
    // (e.g. 10000 * 10**18).
    function updateDebt(uint256 _debtId) public {
        uint256 _prevCheck = __loanCodec.loanLastChecked(_debtId);

        // Find time intervals passed
        __loanManager.updateLoanState(_debtId);

        uint256 _firIntervals = __loanCodec.totalFirIntervals(
            _debtId,
            __loanCodec.loanLastChecked(_debtId) - _prevCheck
        );

        // Update debt
        if (_firIntervals > 0) {
            uint256 _totalDebt = __anzaToken.totalSupply(_debtId * 2);

            uint256 _updatedDebt = Interest.compoundWithTopoff(
                _totalDebt,
                __loanCodec.fixedInterestRate(_debtId),
                _firIntervals
            );

            __anzaToken.mint(_debtId, _updatedDebt - _totalDebt);
        }
    }

    function _depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) internal {
        address _lender = __anzaToken.lenderOf(_debtId);
        uint256 _balance = __anzaToken.balanceOf(_lender, _debtId * 2);

        // Update lender's withdrawable balance
        if (_balance > _payment) {
            withdrawableBalance[_lender] += _payment;

            // Burn ALC debt token
            __anzaToken.burn(_lender, _debtId * 2, _payment);
        } else {
            withdrawableBalance[_lender] += _balance;
            withdrawableBalance[_payer] += _payment - _balance;

            // Burn ALC debt token
            __anzaToken.burn(_lender, _debtId * 2, _balance);
        }

        // Conditionally burn replica
        if (!__loanManager.checkLoanActive(_debtId)) {
            __anzaToken.burnBorrowerToken(_debtId);
        }
    }
}
