// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/console.sol";

import {DebtNotary} from "./LoanNotary.sol";
import "./interfaces/IAnzaToken.sol";
import "./interfaces/IAnzaDebtStorefront.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanTreasurey.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AnzaDebtStorefront is
    IAnzaDebtStorefront,
    DebtNotary,
    ReentrancyGuard
{
    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address public immutable loanContract;
    address public immutable loanTreasurer;
    address public immutable anzaToken;

    mapping(address beneficiary => uint256) private __proceeds;

    constructor(
        address _loanContract,
        address _loanTreasurer,
        address _anzaToken
    ) DebtNotary("AnzaDebtStorefront", "0") {
        loanContract = _loanContract;
        loanTreasurer = _loanTreasurer;
        anzaToken = _anzaToken;
    }

    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) external payable {
        (bool success, ) = address(this).call{value: msg.value}(
            abi.encodeWithSignature(
                "buyDebt(uint256,uint256,bytes)",
                ILoanContract(loanContract).getCollateralDebtId(
                    _collateralAddress,
                    _collateralId
                ),
                _termsExpiry,
                _sellerSignature
            )
        );
        require(success);
    }

    function buyDebt(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable nonReentrant {
        // Verify borrower participation
        address _borrower = _getSigner(
            _debtId,
            DebtListingParams({
                price: msg.value,
                debtId: _debtId,
                debtListingNonce: ILoanTreasurey(loanTreasurer)
                    .getDebtSaleNonce(_debtId),
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            IAnzaToken(anzaToken).borrowerOf
        );

        // Transfer debt
        address _purchaser = msg.sender;
        (bool _success, ) = loanTreasurer.call{value: msg.value}(
            abi.encodeWithSignature(
                "executeDebtPurchase(uint256,address,address)",
                _debtId,
                _borrower,
                _purchaser
            )
        );
        require(_success);

        emit DebtPurchased(_purchaser, _debtId, msg.value);
    }

    function buySponsorship(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable nonReentrant {
        // Verify lender participation
        address _lender = _getSigner(
            _debtId,
            DebtListingParams({
                price: msg.value,
                debtId: _debtId,
                debtListingNonce: ILoanTreasurey(loanTreasurer)
                    .getDebtSaleNonce(_debtId),
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            IAnzaToken(anzaToken).lenderOf
        );

        // Transfer debt
        address _purchaser = msg.sender;
        (bool _success, ) = loanTreasurer.call{value: msg.value}(
            abi.encodeWithSignature(
                "executeSponsorshipPurchase(uint256,address,address)",
                _debtId,
                _lender,
                _purchaser
            )
        );
        require(_success);

        emit DebtPurchased(_purchaser, _debtId, msg.value);
    }

    function refinance() public payable nonReentrant {}
}
