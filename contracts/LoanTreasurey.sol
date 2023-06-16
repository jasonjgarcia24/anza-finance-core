// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractFIRIntervals.sol";
import "@lending-constants/LoanContractRoles.sol";
import "@lending-constants/LoanContractStates.sol";
import "@token-constants/AnzaTokenTransferTypes.sol";
import "@market-constants/AnzaDebtMarketRoles.sol";
import {StdTreasureyErrors} from "@custom-errors/StdTreasureyErrors.sol";
import {StdManagerErrors} from "@custom-errors/StdManagerErrors.sol";
import {StdCodecErrors} from "@custom-errors/StdCodecErrors.sol";

import {ILoanTreasurey} from "@lending-interfaces/ILoanTreasurey.sol";
import {ICollateralVault} from "@lending-interfaces/ICollateralVault.sol";
import {TreasureyAccessController} from "@lending-access/TreasureyAccessController.sol";
import {LibLoanContractInterest as Interest} from "@lending-libraries/LibLoanContract.sol";

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
        if (updateDebt(_debtId)) {
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
        if (_payment == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

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
        if (_payment == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

        if (_anzaToken.borrowerOf(_debtId) != _borrower)
            revert StdManagerErrors.InvalidParticipant();

        _depositPayment(_borrower, _debtId, _payment);

        emit Deposited(_debtId, _borrower, _payment);
    }

    function withdrawFromBalance(
        uint256 _amount
    ) external nonReentrant returns (bool) {
        address _payee = msg.sender;

        if (_amount == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

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
     *   from the payment, if any, will be transferred to the original borrower's
     *   account and the purchaser will be able to withdraw the collateral to
     *   their account. In this case, the borrower will forfeit the collateral to
     *   the purchaser at the debt's value.
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
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower,
        address _purchaser
    )
        external
        payable
        onlyRole(_DEBT_MARKET_)
        nonReentrant
        returns (bool _results)
    {
        uint256 _payment = msg.value;
        uint256 _collateralDebtCount = _loanContract.collateralDebtCount(
            _collateralAddress,
            _collateralId
        );

        uint256[] memory _debtIds = new uint256[](_collateralDebtCount);
        uint256[] memory _amounts = new uint256[](_collateralDebtCount);

        for (uint256 i = 0; i < _collateralDebtCount; ) {
            (uint256 _debtId, ) = _loanContract.collateralDebtAt(
                _collateralAddress,
                _collateralId,
                i
            );

            // Verify debt is active
            _loanManager.verifyLoanActive(_debtId);

            // Update debt
            if (!updateDebt(_debtId)) revert StdCodecErrors.InactiveLoanState();

            // Transfer collateral
            uint256 _debtBalance = _loanContract.debtBalance(_debtId);

            // Transfer collateral
            if (_payment >= _debtBalance) {
                _depositPayment(_purchaser, _debtId, _debtBalance);

                _collateralVault.withdraw(_purchaser, _debtId);

                _payment -= _debtBalance;
            }
            // Setup debt transfer
            else {
                if (_payment > 0)
                    _depositPayment(_purchaser, _debtId, _payment);

                _debtIds[i] = _anzaToken.borrowerTokenId(_debtId);
                _amounts[i] = 1;
            }

            unchecked {
                ++i;
            }

            // Update loan state
            _loanManager.updateLoanState(_debtId);
        }

        withdrawableBalance[_borrower] += _payment;

        _anzaToken.safeBatchTransferFrom(
            _borrower,
            _purchaser,
            _debtIds,
            _amounts,
            abi.encodePacked(_DEBT_TRANSFER_)
        );

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
        onlyRole(_DEBT_MARKET_)
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
        if (!_success) revert StdTreasureyErrors.FailedPurchase();

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
        address _purchaser
    )
        external
        payable
        onlyRole(_DEBT_MARKET_)
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
        if (!_success) revert StdTreasureyErrors.FailedPurchase();

        _results = true;
    }

    // TODO: Need to revisit to ensure accuracy at larger total debt values
    // (e.g. 10000 * 10**18).
    function updateDebt(uint256 _debtId) public returns (bool) {
        uint256 _prevCheck = _loanDebtTerms.loanLastChecked(_debtId);

        // Find time intervals passed
        _loanManager.updateLoanState(_debtId);

        uint256 _firIntervals = _loanCodec.totalFirIntervals(
            _debtId,
            _loanDebtTerms.loanLastChecked(_debtId) - _prevCheck
        );

        // Update debt
        if (_firIntervals > 0) {
            uint256 _totalDebt = _anzaToken.totalSupply(_debtId * 2);

            uint256 _updatedDebt = Interest.compoundWithTopoff(
                _totalDebt,
                _loanDebtTerms.fixedInterestRate(_debtId),
                _firIntervals
            );

            _anzaToken.mint(_debtId, _updatedDebt - _totalDebt);
        }

        return
            !_loanManager.checkLoanExpired(_debtId) &&
            !_loanManager.checkLoanClosed(_debtId);
    }

    function _depositPayment(
        address _payer,
        uint256 _debtId,
        uint256 _payment
    ) internal {
        if (_payment == 0) revert StdTreasureyErrors.InvalidFundsTransfer();

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
