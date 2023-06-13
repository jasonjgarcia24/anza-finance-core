// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {CanceledListing} from "@custom-errors/StdBaseMarketErrors.sol";

import {IAnzaDebtStorefront} from "@market-interfaces/IAnzaDebtStorefront.sol";
import {AnzaBaseMarketParticipant, NonceLocker} from "@market-databases/AnzaBaseMarketParticipant.sol";
import {AnzaDebtStorefrontAccessController} from "@market-access/AnzaDebtStorefrontAccessController.sol";
import {ILoanContract} from "@lending-interfaces/ILoanContract.sol";

contract AnzaDebtStorefront is
    IAnzaDebtStorefront,
    AnzaBaseMarketParticipant,
    AnzaDebtStorefrontAccessController
{
    using NonceLocker for NonceLocker.Nonce;

    constructor(
        address _anzaToken,
        address _loanContract,
        address _loanTreasurer
    )
        AnzaDebtStorefrontAccessController(
            _anzaToken,
            _loanContract,
            _loanTreasurer
        )
    {}

    modifier onlyActiveListing(bytes calldata _signature) {
        if (_canceledListings[keccak256(_signature)]) revert CanceledListing();
        _;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IAnzaDebtStorefront).interfaceId ||
            AnzaDebtStorefrontAccessController.supportsInterface(interfaceId);
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
     * @dev Reverts if the caller is not the borrower of the debt ID.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the listing type is UNDEFINED.
     *
     * Emits a {ListingRegistered} event.
     */
    function publishListing(uint256 _debtId) external returns (bool _success) {
        // Verify the debt ID is active
        _loanManager.verifyLoanActive(_debtId);

        // Verify the caller is the current borrower of the debt
        _verifySeller(_debtId);

        // Increment the debt nonce
        _nonces.push(NonceLocker.spawn(msg.sender, uint8(ListingType.DEBT)));

        emit ListingRegistered(
            msg.sender,
            _debtId,
            uint8(ListingType.DEBT),
            _nonces.length
        );

        _success = true;
    }

    /**
     * Executes a debt purchase for a given debt ID.
     *
     * @notice This function is the primary entrypoint for transfer of debt from
     * a borrower to a purchaser. Following a successfull execution of this
     * function, the debt will be owned by the purchaser and the proceeds will
     * be sent to the loan treasurer for distribution to the borrower and lender.
     * The transfer of debt is conducted through the transfer of the borrower's
     * AnzaToken, which is minted to the borrower upon loan origination. Therefore,
     * no new loan contract is required.
     *
     * @param _collateralAddress The address of the collateral contract.
     * @param _collateralId The ID of the collateral token.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _sellerSignature The signature of the borrower
     * {see LoanNotary:DebtNotary-__typeDataHash}.
     *
     * @dev Reverts if the listing is cancelled.
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the debt ID is owned by the caller.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature
     * construction.
     */
    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable onlyActiveListing(_sellerSignature) {
        _buyListing(
            _collateralAddress,
            _collateralId,
            _termsExpiry,
            msg.value,
            _sellerSignature
        );
    }

    /**
     * Executes a published debt purchase for a given debt ID.
     *
     * @notice This function is the primary entrypoint for transfer of debt from
     * a borrower to a purchaser. Following a successfull execution of this
     * function, the debt will be owned by the purchaser and the proceeds will
     * be sent to the loan treasurer for distribution to the borrower and lender(s).
     *
     * @param _collateralAddress The address of the collateral contract.
     * @param _collateralId The ID of the collateral token.
     * @param _listingNonce The nonce of the published listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _sellerSignature The signature of the borrower
     * {see LoanNotary:DebtNotary-__typeDataHash}.
     *
     * @dev Reverts if the listing is cancelled.
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the borrower of the debt ID.
     * @dev Reverts if the listing nonce listing type is invalid.
     * @dev Reverts if the listing nonce is invalid.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature construction.
     */
    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable onlyActiveListing(_sellerSignature) {
        _buyListing(
            _collateralAddress,
            _collateralId,
            _termsExpiry,
            _listingNonce,
            msg.value,
            _sellerSignature
        );
    }

    /**
     * Non-primary entrypoint for executing a purchase of a debt listing.
     *
     * @param _collateralAddress The contract address of the token's debt to purchase.
     * @param _collateralId The token ID of the debt listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _price The price of the debt listing.
     * @param _sellerSignature The signature of the seller.
     *
     * Emits a {ListingPurchased} event.
     *
     * @dev See the {buyListing} nonpublished versions.
     */
    function _buyListing(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _sellerSignature
    ) internal {
        (uint256 _debtId, ) = _loanContract.collateralDebtAt(
            _collateralAddress,
            _collateralId,
            0
        );

        // Verify seller participation
        address _seller = _getSigner(
            _debtId,
            DebtParams({
                price: _price,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                listingNonce: _nonces.length,
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            _anzaTokenIndexer.borrowerOf
        );

        // Update listing nonce
        _nonces.push(NonceLocker.ruin(msg.sender, uint8(ListingType.DEBT)));

        // Transfer debt
        _transferDebt(_collateralAddress, _collateralId, _price, _seller);

        // Emit refinance purchase event
        emit ListingPurchased(
            msg.sender,
            uint8(ListingType.DEBT),
            _collateralAddress,
            _collateralId
        );
    }

    /**
     * Non-primary entrypoint for executing a purchase of a debt listing.
     *
     * @param _collateralAddress The contract address of the token's debt to purchase.
     * @param _collateralId The token ID of the debt listing to purchase.
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
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _sellerSignature
    ) internal {
        (uint256 _debtId, ) = _loanContract.collateralDebtAt(
            _collateralAddress,
            _collateralId,
            0
        );

        // Verify nonce is unused (handles reentrancy and replay attacks)
        _nonces[_listingNonce].oneTimeAccess(uint8(ListingType.DEBT));

        // Verify seller participation
        address _seller = _getSigner(
            _debtId,
            DebtParams({
                price: _price,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            _anzaTokenIndexer.ownerOf
        );

        // Transfer debt
        _transferDebt(_collateralAddress, _collateralId, _price, _seller);

        // Emit refinance purchase event
        emit ListingPurchased(
            msg.sender,
            uint8(ListingType.DEBT),
            _collateralAddress,
            _collateralId
        );
    }

    /**
     * Non-primary entrypoint for invoking debt transfer through the treasurer.
     *
     * @param _collateralAddress The address of the collateral contract.
     * @param _collateralId The ID of the collateral token.
     * @param _price The price of the listing.
     * @param _seller The seller of the listing.
     *
     * @dev Reverts if the listing type is not a valid.
     *
     * @dev See {LoanTreasurey-executeDebtPurchase}.
     */
    function _transferDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _price,
        address _seller
    ) internal {
        (bool _success, ) = loanTreasurerAddress.call{value: _price}(
            abi.encodeWithSignature(
                "executeDebtPurchase(address,uint256,address,address)",
                _collateralAddress,
                _collateralId,
                _seller,
                msg.sender
            )
        );
        require(_success);
    }
}
