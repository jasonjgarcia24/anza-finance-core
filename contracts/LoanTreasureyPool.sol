// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ILoanContract.sol";
import {LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";

error InvalidParticipant(address account);
error InsufficientFunds(uint256 amount);

contract LoanTreasureyPool is Ownable, ReentrancyGuard {
    using Address for address payable;

    event Deposited(address indexed _payee, uint256 weiAmount);
    event Withdrawn(address indexed _payee, uint256 weiAmount);

    uint256 public poolBalance;
    address private __loanContract;
    mapping(address => uint256) private __balances;

    constructor(address _loanContract) {
        __loanContract = _loanContract;
    }

    function approveLoanContract(
        Metadata.TokenData memory _tokenData,
        uint256 _collateralNonce,
        uint256 _termsExpiry,
        bytes calldata _borrowerSignature,
        bytes calldata _lenderSignature
    ) external payable onlyOwner {
        if (msg.value != _tokenData.principal)
            revert InsufficientFunds({amount: msg.value});
    }

    function depositPool(address _payee) external payable {
        uint256 _amount = msg.value;
        __deposit(_payee, _amount);
    }

    function depositPayment(address _lender, uint256 _debtId)
        external
        payable
        nonReentrant
    {
        ILoanContract _loanContract = ILoanContract(__loanContract);
        address _borrower = msg.sender;

        if (_borrower != _loanContract.borrowerOf(_debtId))
            revert InvalidParticipant({account: _borrower});

        uint256 _payment = msg.value;

        __deposit(_lender, _payment);

        // ILoanContract(__loanContract).recordPayment(_debtId);
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param _payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function __deposit(address _payee, uint256 _payment) private {
        __balances[_payee] += _payment;
        poolBalance += _payment;

        emit Deposited(_payee, _payment);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param _payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function __withdraw(address payable _payee, uint256 _payment)
        private
        nonReentrant
    {
        if (_payment <= __balances[_payee])
            revert InsufficientFunds({amount: __balances[_payee]});

        __balances[_payee] -= _payment;
        poolBalance -= _payment;

        _payee.sendValue(_payment);

        emit Withdrawn(_payee, _payment);
    }
}
