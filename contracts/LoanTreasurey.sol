// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanCollateralVault.sol";
import "./token/interfaces/IAnzaToken.sol";
import {LibOfficerRoles as Roles} from "./libraries/LibLoanContract.sol";
import {LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";

error InvalidParticipant(address account);
error InsufficientFunds(uint256 amount);

contract LoanTreasurey is Ownable, ReentrancyGuard {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    address public immutable loanContract;
    address public immutable loanCollateralVault;
    address public immutable anzaToken;
    uint256 public poolBalance;

    // Mapping from participant to withdrawable balance
    mapping(address => uint256) public withdrawableBalance;

    constructor(
        address _loanContract,
        address _loanCollateralVault,
        address _anzaToken
    ) {
        loanContract = _loanContract;
        loanCollateralVault = _loanCollateralVault;
        anzaToken = _anzaToken;
    }

    function sponsorPayment(uint256 _debtId) external payable {
        _depositPayment(_debtId, msg.value);
    }

    function depositPayment(uint256 _debtId) external payable {
        if (msg.sender != ILoanContract(loanContract).borrower(_debtId))
            revert ILoanContract.InvalidParticipant(msg.sender);

        _depositPayment(_debtId, msg.value);
    }

    function withdrawPayment(uint256 _amount) external returns (bool) {
        address _payee = msg.sender;

        if (withdrawableBalance[_payee] < _amount)
            revert ILoanContract.InvalidFundsTransfer({amount: _amount});

        // Update lender's withdrawable balance
        withdrawableBalance[_payee] -= _amount;

        // Transfer payment funds to lender
        (bool _success, ) = _payee.call{value: _amount}("");
        require(_success);

        return _success;
    }

    function withdrawCollateral(uint256 _debtId) external {
        address _borrower = msg.sender;
        bytes32 _role = keccak256(abi.encodePacked(_borrower, _debtId));

        if (IAccessControl(anzaToken).hasRole(_role, _borrower) == false)
            revert InvalidParticipant(_borrower);

        ILoanCollateralVault(loanCollateralVault).withdraw(_borrower, _debtId);
    }

    function _depositPayment(uint256 _debtId, uint256 _payment) internal {
        IAnzaToken _anzaTokenContract = IAnzaToken(anzaToken);

        address _lender = _anzaTokenContract.lenderOf(_debtId);

        // Update lender's withdrawable balance
        withdrawableBalance[_lender] += _payment;

        // Burn ALC debt token
        _anzaTokenContract.burn(_lender, _debtId * 2, _payment);

        // Conditionally update debt
        ILoanContract(loanContract).updateLoanState(_debtId);
    }

    // // function sponsorPayment(uint256 _debtId) external payable {
    // //     _depositPayment(_debtId, msg.value);
    // // }

    // // function depositPayment(uint256 _debtId) external payable {
    // //     if (msg.sender != borrower(_debtId))
    // //         revert InvalidParticipant(msg.sender);

    // //     _depositPayment(_debtId, msg.value);
    // // }

    // // function withdrawPayment(uint256 _amount) external returns (bool) {
    // //     address _payee = msg.sender;

    // //     if (withdrawableBalance[_payee] < _amount) {
    // //         revert InvalidFundsTransfer({amount: _amount});
    // //     }

    // //     // Update lender's withdrawable balance
    // //     withdrawableBalance[_payee] -= _amount;

    // //     // Transfer payment funds to lender
    // //     (bool _success, ) = _payee.call{value: _amount}("");
    // //     require(_success);

    // //     return _success;
    // // }

    // // function _depositPayment(uint256 _debtId, uint256 _payment) internal {
    // //     address _lender = anzaToken.lenderOf(_debtId);

    // //     // Update lender's withdrawable balance
    // //     withdrawableBalance[_lender] += _payment;

    // //     // Burn ALC debt token
    // //     anzaToken.burn(_lender, _debtId * 2, _payment);

    // //     // Conditionally update debt
    // //     updateLoanState(_debtId);
    // // }

    // function depositPool(address _payee) external payable {
    //     uint256 _amount = msg.value;
    //     __deposit(_payee, _amount);
    // }

    // function depositPayment(
    //     address _lender,
    //     uint256 _debtId
    // ) external payable nonReentrant {
    //     // ILoanContract _loanContract = ILoanContract(loanContract);
    //     // address _borrower = msg.sender;
    //     // if (_borrower != _loanContract.borrowerOf(_debtId))
    //     //     revert InvalidParticipant({account: _borrower});
    //     // uint256 _payment = msg.value;
    //     // __deposit(_lender, _payment);
    //     // // ILoanContract(__loanContract).recordPayment(_debtId);
    // }

    // /**
    //  * @dev Stores the sent amount as credit to be withdrawn.
    //  * @param _payee The destination address of the funds.
    //  *
    //  * Emits a {Deposited} event.
    //  */
    // function __deposit(address _payee, uint256 _payment) private {
    //     __balances[_payee] += _payment;

    //     poolBalance += _payment;

    //     emit Deposited(_payee, _payment);
    // }

    // /**
    //  * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
    //  * recipient.
    //  *
    //  * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
    //  * Make sure you trust the recipient, or are either following the
    //  * checks-effects-interactions pattern or using {ReentrancyGuard}.
    //  *
    //  * @param _payee The address whose funds will be withdrawn and transferred to.
    //  *
    //  * Emits a {Withdrawn} event.
    //  */
    // function __withdraw(
    //     address payable _payee,
    //     uint256 _payment
    // ) private nonReentrant {
    //     if (_payment <= __balances[_payee])
    //         revert InsufficientFunds({amount: __balances[_payee]});

    //     __balances[_payee] -= _payment;
    //     poolBalance -= _payment;
    //     _payee.sendValue(_payment);

    //     emit Withdrawn(_payee, _payment);
    // }
}
