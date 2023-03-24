// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./interfaces/ILoanTreasurey.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanCollateralVault.sol";
import "./token/interfaces/IAnzaToken.sol";
import "./abdk-libraries-solidity/ABDKMath64x64.sol";
import {LibOfficerRoles as Roles} from "./libraries/LibLoanContract.sol";
import {LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";

contract LoanTreasurey is ILoanTreasurey, Ownable, ReentrancyGuard {
    using Address for address payable;

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

    function withdrawCollateral(uint256 _debtId) external returns (bool) {
        address _borrower = msg.sender;
        bytes32 _role = keccak256(abi.encodePacked(_borrower, _debtId));

        // The borrower is essentially stored in the borrower Anza Replica
        // token's access control
        if (!IAccessControl(anzaToken).hasRole(_role, _borrower))
            revert InvalidParticipant(_borrower);

        return
            ILoanCollateralVault(loanCollateralVault).withdraw(
                _borrower,
                _debtId
            );
    }

    // TODO: Need to revisit to ensure accuracy at larger total debt values
    // (e.g. 10000 * 10**18).
    function setBalanceWithInterest(uint256 _debtId) public returns (uint256) {
        ILoanContract _loanContract = ILoanContract(loanContract);

        uint256 _prevCheck = _loanContract.loanLastChecked(_debtId);
        _loanContract.updateLoanState(_debtId);

        // Calculate time intervals passed
        uint256 _firIntervals = _loanContract.totalFirIntervals(
            _debtId,
            _loanContract.loanLastChecked(_debtId) - _prevCheck
        );
        uint256 _totalDebt = IAnzaToken(anzaToken).totalSupply(_debtId * 2);
        uint256 _fixedInterestRate = _loanContract.fixedInterestRate(_debtId);

        if (_firIntervals > 0) {
            return
                _compound(_totalDebt, _fixedInterestRate, _firIntervals) +
                _topoff(_totalDebt, _fixedInterestRate, _firIntervals);
        } else {
            return IAnzaToken(anzaToken).totalSupply(_debtId * 2);
        }
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
        if (!_loanContract.checkLoanActive(_debtId)) {
            _anzaTokenContract.burn(
                _loanContract.borrower(_debtId),
                _anzaTokenContract.borrowerTokenId(_debtId),
                1
            );
        }
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

    // Topoff to account for small inaccuracies in compound calculations
    function _topoff(
        uint256 _totalDebt,
        uint256 _fixedInterestRate,
        uint256 _firIntervals
    ) internal pure returns (uint256) {
        return
            _fixedInterestRate == 100 ? 0 : _fixedInterestRate >= 10
                ? _firIntervals == 1 && _totalDebt >= 10
                    ? 1
                    : _totalDebt >= 1000
                    ? (_totalDebt / (10 ** 21)) >= 1 ? 10 : 1
                    : 0
                : _fixedInterestRate == 1
                ? _firIntervals == 1 && _totalDebt >= 100
                    ? (_totalDebt / (10 ** 21)) >= 1 ? 10 : 1
                    : 0
                : 0;
    }
}
