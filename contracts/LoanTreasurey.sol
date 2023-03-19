// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanCollateralVault.sol";
import "./token/interfaces/IAnzaToken.sol";
import "./abdk-libraries-solidity/ABDKMath64x64.sol";
import {LibOfficerRoles as Roles} from "./libraries/LibLoanContract.sol";
import {LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";

error InvalidParticipant(address account);
error InsufficientFunds(uint256 amount);
error InactiveLoanState(uint256 debtId);

contract LoanTreasurey is Ownable, ReentrancyGuard {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    /* ------------------------------------------------ *
     *                Contract Constants                *
     * ------------------------------------------------ */
    uint256 private constant _SECONDS_PER_YEAR_RATIO_SCALED_ =
        (365 * 24 * 60 * 60) * 100;

    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address public immutable loanContract;
    address public immutable loanCollateralVault;
    address public immutable anzaToken;
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

        if (_amount == 0 || _amount > withdrawableBalance[_payee])
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
        ILoanContract _loanContract = ILoanContract(loanContract);
        IAnzaToken _anzaTokenContract = IAnzaToken(anzaToken);
        address _lender = _anzaTokenContract.lenderOf(_debtId);

        // Update lender's withdrawable balance
        withdrawableBalance[_lender] += _payment;

        // Burn ALC debt token
        _anzaTokenContract.burn(_lender, _debtId * 2, _payment);

        // Update loan state
        _loanContract.updateLoanState(_debtId);

        // Conditionally burn replica
        if (_loanContract.checkLoanActive(_debtId) == false) {
            _anzaTokenContract.burn(
                _loanContract.borrower(_debtId),
                _anzaTokenContract.borrowerTokenId(_debtId),
                1
            );
        }
    }

    function getBalanceWithInterest(uint256 _debtId) public returns (uint256) {
        ILoanContract _loanContract = ILoanContract(loanContract);

        uint256 _prevCheck = _loanContract.loanLastChecked(_debtId);
        _loanContract.updateLoanState(_debtId);
        uint256 _timeDiff = _loanContract.loanLastChecked(_debtId) - _prevCheck;

        if (_timeDiff > 0) {
        uint256 _newBalance = _compound(
            IAnzaToken(anzaToken).totalSupply(_debtId * 2),
            ILoanContract(loanContract).fixedInterestRate(_debtId),
            20
        );

        console.log(IAnzaToken(anzaToken).totalSupply(_debtId * 2));

        return _newBalance;
    }

    function _compound(
        uint256 _principal,
        uint256 _ratio,
        uint256 _n
    ) internal pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                _pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(_ratio, 100)
                    ),
                    _n
                ),
                _principal
            );
    }

    function _pow(int128 _x, uint256 _n) internal pure returns (int128) {
        int128 _r = ABDKMath64x64.fromUInt(1);
        while (_n > 0) {
            if (_n % 2 == 1) {
                _r = ABDKMath64x64.mul(_r, _x);
                _n -= 1;
            } else {
                _x = ABDKMath64x64.mul(_x, _x);
                _n /= 2;
            }
        }

        return _r;
    }

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
