// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {StdBaseMarketErrors} from "@custom-errors/StdBaseMarketErrors.sol";

import {IAnzaSponsorshipStorefront} from "@storefronts-interfaces/IAnzaSponsorshipStorefront.sol";
import {AnzaBaseMarketParticipant, NonceLocker} from "@markets-databases/AnzaBaseMarketParticipant.sol";
import {AnzaSponsorshipStorefrontAccessController} from "@markets-access/AnzaSponsorshipStorefrontAccessController.sol";
import {ILoanContract} from "@base/interfaces/ILoanContract.sol";

contract AnzaSponsorshipStorefront is
    IAnzaSponsorshipStorefront,
    AnzaBaseMarketParticipant,
    AnzaSponsorshipStorefrontAccessController
{
    using NonceLocker for NonceLocker.Nonce;

    constructor(
        address _anzaToken,
        address _loanContract,
        address _loanTreasurer
    )
        AnzaSponsorshipStorefrontAccessController(
            _anzaToken,
            _loanContract,
            _loanTreasurer
        )
    {}

    modifier onlyActiveListing(bytes calldata _signature) {
        if (_canceledListings[keccak256(_signature)])
            revert StdBaseMarketErrors.CanceledListing();
        _;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IAnzaSponsorshipStorefront).interfaceId ||
            AnzaSponsorshipStorefrontAccessController.supportsInterface(
                interfaceId
            );
    }

    /**
     * Publishes a debt listing nonce for a given debt ID.
     *
     * @notice While publishing a debt listing is not required to sell a debt, it
     * is a convenience function for sellers to lock in a listing nonce for a
     * given signed offchain listing. It is important to be aware that publishing
     * the listing does not store the actual listing onchain, but rather a nonce
     * for the listing. The nonce is used to verify the listing when a buyer
     * attempts to purchase the debt {see LoanNotary:LoanNotary-__structHash}.
     *
     * @param _debtId The debt ID to publish a debt listing for.
     * @return _success True if the listing was published successfully.
     *
     * @dev Reverts if the caller is not the lender of the debt ID.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the listing type is UNDEFINED.
     *
     * Emits a {ListingRegistered} event.
     */
    function publishListing(uint256 _debtId) external returns (bool _success) {
        // Verify the debt ID is active
        _loanManager.verifyLoanActive(_debtId);

        // Validate the caller is the current sponsor of the debt
        _verifySeller(_debtId);

        // Increment the debt nonce
        _nonces.push(
            NonceLocker.spawn(msg.sender, uint8(ListingType.SPONSORSHIP))
        );

        emit ListingRegistered(
            msg.sender,
            _debtId,
            uint8(ListingType.SPONSORSHIP),
            _nonces.length
        );

        _success = true;
    }

    /**
     * Executes a sponsorship purchase for a given debt ID.
     *
     * @notice This function is the primary entrypoint for purchasing a sponsorship
     * for a given debt ID. Following a successfull execution of this function, a
     * new loan contract will be created and the amount of debt in the agreement will
     * be reallocated from the original loan contract to the new loan contract. The
     * lender of the original loan contract will be paid out the amount of the debt
     * that was reallocated and the borrower will be issued a new loan for the same
     * amount. This will result in the borrower having an additional loan and a new
     * lender being introduced into the borrower's loan conditions for a given
     * collateral. Note, the new loan contract will be created with the same contract
     * terms as the original loan contract.
     *
     * @param _debtId The debt ID to sponsor.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _sellerSignature The signature of the lender.
     *
     * @dev Reverts if the listing is cancelled.
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the lender of the debt ID.
     *
     * @dev See {AnzaNotary:AnzaNotary-typeDataHash} for signature construction.
     */
    function buySponsorship(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable onlyActiveListing(_sellerSignature) {
        _buyListing(_debtId, _termsExpiry, msg.value, _sellerSignature);
    }

    /**
     * Executes a published sponsorship purchase for a given debt ID.
     *
     * @notice This function is the primary entrypoint for purchasing a sponsorship
     * for a given debt ID. Following a successfull execution of this function, a
     * new loan contract will be created and the amount of debt in the agreement will
     * be reallocated from the original loan contract to the new loan contract. The
     * lender of the original loan contract will be paid out the amount of the debt
     * that was reallocated and the borrower will be issued a new loan for the same
     * amount. This will result in the borrower having an additional loan and a new
     * lender being introduced into the borrower's loan conditions for a given
     * collateral. Note, the new loan contract will be created with the same contract
     * terms as the original loan contract.
     *
     * @param _debtId The debt ID to sponsor.
     * @param _listingNonce The nonce of the published listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _sellerSignature The signature of the lender.
     *
     * @dev Reverts if the listing is cancelled.
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the lender of the debt ID.
     * @dev Reverts if the listing nonce listing type is invalid.
     * @dev Reverts if the listing nonce is invalid.
     *
     * @dev See {AnzaNotary:AnzaNotary-typeDataHash} for signature construction.
     */
    function buySponsorship(
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable onlyActiveListing(_sellerSignature) {
        _buyListing(
            _debtId,
            _listingNonce,
            _termsExpiry,
            msg.value,
            _sellerSignature
        );
    }

    /**
     * Non-primary entrypoint for executing a purchase of a sponsorship listing.
     *
     * @param _debtId The debt ID to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _price The price of the debt listing.
     * @param _sellerSignature The signature of the seller.
     *
     * Emits a {ListingPurchased} event.
     *
     * @dev See the {buyListing} nonpublished versions.
     */
    function _buyListing(
        uint256 _debtId,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _sellerSignature
    ) internal {
        // Verify seller participation
        address _seller = _getSigner(
            _debtId,
            SponsorshipParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _nonces.length,
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            _anzaTokenIndexer.lenderOf
        );

        // Update listing nonce
        _nonces.push(
            NonceLocker.ruin(msg.sender, uint8(ListingType.SPONSORSHIP))
        );

        // Transfer debt
        _transferSponsorship(_debtId, _price, _seller);

        // Emit refinance purchase event
        emit ListingPurchased(
            msg.sender,
            uint8(ListingType.SPONSORSHIP),
            address(_anzaTokenIndexer),
            _anzaTokenIndexer.lenderTokenId(_debtId)
        );
    }

    /**
     * Non-primary entrypoint for executing a purchase of a sponsoship listing.
     *
     * @param _debtId The debt ID to purchase.
     * @param _listingNonce The nonce of the published debt listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _price The price of the debt listing.
     * @param _sellerSignature The signature of the seller.
     *
     * Emits a {ListingPurchased} event.
     *
     * @dev See the {buyListing} nonpublished versions.
     */
    function _buyListing(
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _sellerSignature
    ) internal {
        // Verify nonce is unused (handles reentrancy and replay attacks)
        _nonces[_listingNonce].oneTimeAccess(uint8(ListingType.SPONSORSHIP));

        // Verify seller participation
        address _seller = _getSigner(
            _debtId,
            SponsorshipParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            _anzaTokenIndexer.lenderOf
        );

        // Transfer debt
        _transferSponsorship(_debtId, _price, _seller);

        // Emit refinance purchase event
        emit ListingPurchased(
            msg.sender,
            uint8(ListingType.SPONSORSHIP),
            address(_anzaTokenIndexer),
            _anzaTokenIndexer.lenderTokenId(_debtId)
        );
    }

    /**
     * Non-primary entrypoint for invoking sponsorship transfer through the
     * treasurer.
     *
     * @param _debtId The debt ID to transfer.
     * @param _price The price of the listing.
     * @param //_seller The seller of the listing.
     *
     * @dev Reverts if the listing type is not a valid.
     *
     * @dev See {LoanTreasurey-executeSponsorshipPurchase}.
     */
    function _transferSponsorship(
        uint256 _debtId,
        uint256 _price,
        address /* _seller */
    ) internal {
        (bool _success, bytes memory _data) = loanTreasurerAddress.call{
            value: _price
        }(
            abi.encodeWithSignature(
                "executeSponsorshipPurchase(uint256,address)",
                _debtId,
                msg.sender
            )
        );

        // Return error if one is present
        if (!_success) _revert(_data);
    }
}
