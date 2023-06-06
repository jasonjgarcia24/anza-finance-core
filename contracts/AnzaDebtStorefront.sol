// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../lib/forge-std/src/console.sol";

import {IAnzaDebtStorefront} from "./interfaces/IAnzaDebtStorefront.sol";
import {IAnzaToken} from "./interfaces/IAnzaToken.sol";
import {ILoanTreasurey} from "./interfaces/ILoanTreasurey.sol";
import {ListingNotary} from "./LoanNotary.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AnzaDebtStorefront is
    IAnzaDebtStorefront,
    ListingNotary,
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
    ) ListingNotary("AnzaDebtStorefront", "0") {
        loanContract = _loanContract;
        loanTreasurer = _loanTreasurer;
        anzaToken = _anzaToken;
    }

    function buyDebt(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable {
        _buyListing(
            IAnzaToken(anzaToken).borrowerTokenId(_debtId),
            _termsExpiry,
            msg.value,
            _sellerSignature,
            "executeDebtPurchase(uint256,address,address)"
        );
    }

    function buySponsorship(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable {
        _buyListing(
            IAnzaToken(anzaToken).lenderTokenId(_debtId),
            _termsExpiry,
            msg.value,
            _sellerSignature,
            "executeSponsorshipPurchase(uint256,address,address)"
        );
    }

    function refinance() public payable nonReentrant {}

    function _buyListing(
        uint256 _tokenId,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _sellerSignature,
        string memory _purchaseListingMethod
    ) internal virtual nonReentrant {
        uint256 _debtId = IAnzaToken(anzaToken).debtId(_tokenId);

        // Verify seller participation
        address _seller = _getSigner(
            _tokenId,
            ListingParams({
                price: _price,
                debtId: _debtId,
                listingNonce: ILoanTreasurey(loanTreasurer).getDebtSaleNonce(
                    _debtId
                ),
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            IAnzaToken(anzaToken).ownerOf
        );

        // Transfer debt
        (bool _success, ) = loanTreasurer.call{value: _price}(
            abi.encodeWithSignature(
                _purchaseListingMethod,
                _debtId,
                _seller,
                msg.sender
            )
        );
        require(_success);

        emit DebtPurchased(msg.sender, _debtId, _price);
    }
}
