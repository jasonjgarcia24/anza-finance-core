// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "../lib/forge-std/src/console.sol";

import {IAnzaDebtStorefront} from "./interfaces/IAnzaDebtStorefront.sol";
import {IAnzaTokenIndexer} from "./interfaces/IAnzaTokenIndexer.sol";
import {ILoanTreasurey} from "./interfaces/ILoanTreasurey.sol";
import {ILoanManager} from "./interfaces/ILoanManager.sol";
import {ListingNotary, RefinanceNotary} from "./LoanNotary.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AnzaDebtStorefront is
    IAnzaDebtStorefront,
    ListingNotary,
    RefinanceNotary,
    ReentrancyGuard
{
    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address public immutable loanTreasurer;

    ILoanManager immutable _loanManager;
    IAnzaTokenIndexer immutable _anzaTokenIndexer;

    mapping(address beneficiary => uint256) private __proceeds;
    mapping(uint256 debtId => Nonce[]) private __listingNonces;

    constructor(
        address _loanContract,
        address _loanTreasurer,
        address _anzaToken
    )
        ListingNotary("AnzaDebtStorefront:ListingNotary", "0")
        RefinanceNotary("AnzaDebtStorefront:RefinanceNotary", "0")
    {
        loanTreasurer = _loanTreasurer;

        _loanManager = ILoanManager(_loanContract);
        _anzaTokenIndexer = IAnzaTokenIndexer(_anzaToken);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ListingNotary, RefinanceNotary)
        returns (bool)
    {
        return
            interfaceId == type(IAnzaDebtStorefront).interfaceId ||
            ListingNotary.supportsInterface(interfaceId) ||
            RefinanceNotary.supportsInterface(interfaceId);
    }

    /**
     * Returns the address of the loan contract.
     */
    function loanContract() public view returns (address) {
        return address(_loanManager);
    }

    /**
     * Returns the address of the AnzaTokenIndexer.
     */
    function anzaToken() public view returns (address) {
        return address(_anzaTokenIndexer);
    }

    /**
     * Returns the next listing nonce for a given debt ID.
     *
     * The listing nonce is used to verify the listing when a buyer
     * attempts to purchase the debt {see LoanNotary:LoanNotary-__structHash}.
     *
     * @notice The listing nonce is incremented each time a listing is published,
     * therefore the listing nonce provided by this function is the next listing
     * available and can be locked out by publishing a listing.
     *
     * @param _debtId The debt ID to get the listing nonce for.
     */
    function getListingNonce(uint256 _debtId) external view returns (uint256) {
        return __listingNonces[_debtId].length;
    }

    /**
     * Publishes a listing nonce for a given debt ID.
     *
     * @notice While publishing a listing is not required to sell a debt, it is
     * a convenience function for sellers to lock in a listing nonce for a given
     * signed offchain listing. It is important to be aware that publishing the
     * listing does not store the actual listing onchain, but rather a nonce for
     * the listing. The nonce is used to verify the listing when a buyer attempts
     * to purchase the debt {see LoanNotary:LoanNotary-__structHash}.
     *
     * @param _debtId The debt ID to publish a listing for.
     * @param _listingType The type of listing to publish.
     * @return _success True if the listing was published successfully.
     *
     * @dev Reverts if the caller is not the borrower or lender of the debt ID
     * for debt or sponsorship listings respectively.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the listing type is UNDEFINED.
     *
     * Emits a {ListingRegistered} event.
     */
    function publishListing(
        uint256 _debtId,
        ListingType _listingType
    ) external returns (bool _success) {
        // Verify the debt ID is active
        _loanManager.verifyLoanActive(_debtId);

        // Validate the listing type
        if (_listingType == ListingType.UNDEFINED) revert InvalidListingType();

        // Validate the caller with the listing type
        _listingType == ListingType.DEBT
            ? _verifyDebtBorrower(_debtId)
            : _verifyDebtLender(_debtId);

        // Increment the listing nonce
        __listingNonces[_debtId].push(
            Nonce({
                listingType: _listingType,
                publisher: msg.sender,
                locked: false
            })
        );

        emit ListingRegistered(
            msg.sender,
            _debtId,
            uint8(_listingType),
            __listingNonces[_debtId].length
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
     *
     * @param _debtId The debt ID to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _sellerSignature The signature of the seller {see LoanNotary:ListingNotary-__typeDataHash}.
     *
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the debt ID is owned by the caller.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature construction.
     */
    function buyDebt(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable {
        _buyListing(
            _anzaTokenIndexer.borrowerTokenId(_debtId),
            _termsExpiry,
            msg.value,
            ListingType.DEBT,
            _sellerSignature
        );
    }

    /**
     * Executes a published debt purchase for a given debt ID.
     *
     * @notice This function is the primary entrypoint for transfer of debt from
     * a borrower to a purchaser. Following a successfull execution of this
     * function, the debt will be owned by the purchaser and the proceeds will
     * be sent to the loan treasurer for distribution to the borrower and lender.
     *
     * @param _debtId The debt ID to purchase.
     * @param _listingNonce The nonce of the published listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _sellerSignature The signature of the seller
     * {see LoanNotary:ListingNotary-__typeDataHash}.
     *
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the borrower of the debt ID.
     * @dev Reverts if the listing nonce listing type is invalid.
     * @dev Reverts if the listing nonce is invalid.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature construction.
     */
    function buyDebt(
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable {
        _buyListing(
            _anzaTokenIndexer.borrowerTokenId(_debtId),
            _termsExpiry,
            _listingNonce,
            msg.value,
            _sellerSignature
        );
    }

    /**
     * Executes a debt refinance for a given debt ID.
     *
     * @notice This function is the primary entrypoint for refinancing a of debt.
     * Following a successfull execution of this function, a new loan contract will
     * be created and the amount of debt in the agreement will be reallocated from
     * the original loan contract to the new loan contract. The lender of the
     * original loan contract will be paid out the amount of the debt that was
     * reallocated and the borrower will be issued a new loan for the same amount.
     * This will result in the borrower having an additional loan and a new lender
     * being introduced into the borrower's loan conditions for a given collateral.
     *
     * @param _debtId The debt ID to refinance.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _contractTerms The terms of the new loan contract.
     * @param _borrowerSignature The signature of the borrower
     * {see LoanNotary:LoanNotary-__typeDataHash}.
     *
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the borrower of the debt ID.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature construction.
     */
    function buyRefinance(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) public payable {
        _buyRefinance(
            _anzaTokenIndexer.lenderTokenId(_debtId),
            _contractTerms,
            _termsExpiry,
            msg.value,
            _borrowerSignature
        );
    }

    /**
     * Executes a published debt refinance for a given debt ID.
     *
     * @notice This function is the primary entrypoint for refinancing a of debt.
     * Following a successfull execution of this function, a new loan contract will
     * be created and the amount of debt in the agreement will be reallocated from
     * the original loan contract to the new loan contract. The lender of the
     * original loan contract will be paid out the amount of the debt that was
     * reallocated and the borrower will be issued a new loan for the same amount.
     * This will result in the borrower having an additional loan and a new lender
     * being introduced into the borrower's loan conditions for a given collateral.
     *
     * @param _debtId The debt ID to refinance.
     * @param _listingNonce The nonce of the published listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _contractTerms The terms of the new loan contract.
     * @param _borrowerSignature The signature of the borrower
     *
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the borrower of the debt ID.
     * @dev Reverts if the listing nonce listing type is invalid.
     * @dev Reverts if the listing nonce is invalid.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature construction.
     */
    function buyRefinance(
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) public payable {
        _buyRefinance(
            _anzaTokenIndexer.lenderTokenId(_debtId),
            _contractTerms,
            _listingNonce,
            _termsExpiry,
            msg.value,
            _borrowerSignature
        );
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
     * @param _sellerSignature The signature of the seller.
     *
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the lender of the debt ID.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature construction.
     */
    function buySponsorship(
        uint256 _debtId,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable {
        _buyListing(
            _anzaTokenIndexer.lenderTokenId(_debtId),
            _termsExpiry,
            msg.value,
            ListingType.SPONSORSHIP,
            _sellerSignature
        );
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
     * @param _sellerSignature The signature of the seller.
     *
     * @dev Reverts if the signature is invalid.
     * @dev Reverts if the debt ID is not active.
     * @dev Reverts if the caller is the lender of the debt ID.
     * @dev Reverts if the listing nonce listing type is invalid.
     * @dev Reverts if the listing nonce is invalid.
     *
     * @dev See {LibLoanNotary:LibLoanNotary-typeDataHash} for signature construction.
     */
    function buySponsorship(
        uint256 _debtId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable {
        _buyListing(
            _anzaTokenIndexer.lenderTokenId(_debtId),
            _listingNonce,
            _termsExpiry,
            msg.value,
            _sellerSignature
        );
    }

    /**
     * Verifies the caller is the borrower of a given debt ID.
     *
     * @param _debtId The debt ID to verify.
     *
     * @dev Reverts if the caller is not the borrower of the debt ID.
     */
    function _verifyDebtBorrower(uint256 _debtId) internal view {
        if (_anzaTokenIndexer.borrowerOf(_debtId) != msg.sender)
            revert InvalidParticipant();
    }

    /**
     * Verifies the caller is the lender of a given debt ID.
     *
     * @param _debtId The debt ID to verify.
     *
     * @dev Reverts if the caller is not the lender of the debt ID.
     */
    function _verifyDebtLender(uint256 _debtId) internal view {
        if (_anzaTokenIndexer.lenderOf(_debtId) != msg.sender)
            revert InvalidParticipant();
    }

    /**
     * Non-primary entrypoint for executing a purchase of a listing.
     *
     * @param _tokenId The Anza token ID of the listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _price The price of the listing.
     * @param _listingType The type of listing to purchase.
     * @param _sellerSignature The signature of the seller.
     *
     * Emits a {ListingPurchased} event.
     *
     * @dev See {buyListing} & {buySponsorship} nonpublished versions.
     */
    function _buyListing(
        uint256 _tokenId,
        uint256 _termsExpiry,
        uint256 _price,
        ListingType _listingType,
        bytes calldata _sellerSignature
    ) internal {
        uint256 _debtId = _anzaTokenIndexer.debtId(_tokenId);

        // Verify seller participation
        address _seller = _getSigner(
            _tokenId,
            ListingParams({
                price: _price,
                debtId: _debtId,
                listingNonce: __listingNonces[_debtId].length,
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            _anzaTokenIndexer.ownerOf
        );

        // Transfer debt
        _transferDebt(_debtId, _price, _seller, _listingType);

        // Update listing nonce
        __listingNonces[_debtId].push(
            Nonce({
                listingType: _listingType,
                publisher: msg.sender,
                locked: true
            })
        );

        // Emit refinance purchase event
        emit ListingPurchased(msg.sender, _debtId, uint8(_listingType), _price);
    }

    /**
     * Non-primary entrypoint for executing a purchase of a published listing.
     *
     * @param _tokenId The Anza token ID of the listing to purchase.
     * @param _listingNonce The nonce of the published listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _price The price of the listing.
     * @param _sellerSignature The signature of the seller.
     *
     * Emits a {ListingPurchased} event.
     *
     * @dev See {buyListing} & {buySponsorship} published versions.
     */
    function _buyListing(
        uint256 _tokenId,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _sellerSignature
    ) internal {
        uint256 _debtId = _anzaTokenIndexer.debtId(_tokenId);
        Nonce storage _nonce = __listingNonces[_debtId][_listingNonce];

        // Verify nonce is unused (handles reentrancy)
        __nonceLocker(_nonce);

        // Verify seller participation
        address _seller = _getSigner(
            _tokenId,
            ListingParams({
                price: _price,
                debtId: _debtId,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            _anzaTokenIndexer.ownerOf
        );

        // Transfer debt
        _transferDebt(_debtId, _price, _seller, _nonce.listingType);

        // Emit refinance purchase event
        emit ListingPurchased(
            msg.sender,
            _debtId,
            uint8(_nonce.listingType),
            _price
        );
    }

    /**
     * Non-primary entrypoint for executing a purchase of a refinance listing.
     *
     * @param _tokenId The Anza token ID of the listing to purchase.
     * @param _contractTerms The contract terms of the refinance listing.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _price The price of the listing.
     * @param _borrowerSignature The signature of the borrower.
     *
     * Emits a {ListingPurchased} event.
     *
     * @dev See {buyRefinance} nonpublished version.
     */
    function _buyRefinance(
        uint256 _tokenId,
        bytes32 _contractTerms,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _borrowerSignature
    ) internal {
        uint256 _debtId = _anzaTokenIndexer.debtId(_tokenId);

        // Verify seller participation
        address _borrower = _getBorrower(
            _tokenId,
            RefinanceParams({
                price: _price,
                debtId: _debtId,
                contractTerms: _contractTerms,
                listingNonce: __listingNonces[_debtId].length,
                termsExpiry: _termsExpiry
            }),
            _borrowerSignature,
            _anzaTokenIndexer.ownerOf
        );

        // Transfer debt
        _transferDebt(
            _debtId,
            _contractTerms,
            _price,
            _borrower,
            ListingType.REFINANCE
        );

        // Emit refinance purchase event
        emit ListingPurchased(
            msg.sender,
            _debtId,
            uint8(ListingType.REFINANCE),
            _price
        );
    }

    /**
     * Non-primary entrypoint for executing a purchase of a published refinance listing.
     *
     * @param _tokenId The Anza token ID of the listing to purchase.
     * @param _contractTerms The contract terms of the refinance listing.
     * @param _listingNonce The nonce of the published listing to purchase.
     * @param _termsExpiry The expiry of the terms signature.
     * @param _price The price of the listing.
     * @param _borrowerSignature The signature of the borrower.
     *
     * Emits a {ListingPurchased} event.
     *
     * {see buyRefinance} published version.
     */
    function _buyRefinance(
        uint256 _tokenId,
        bytes32 _contractTerms,
        uint256 _listingNonce,
        uint256 _termsExpiry,
        uint256 _price,
        bytes calldata _borrowerSignature
    ) internal {
        uint256 _debtId = _anzaTokenIndexer.debtId(_tokenId);
        Nonce storage _nonce = __listingNonces[_debtId][_listingNonce];

        // Verify nonce is unused (handles reentrancy)
        __nonceLocker(_nonce);

        // Verify borrower participation
        address _borrower = _getBorrower(
            _tokenId,
            RefinanceParams({
                price: _price,
                debtId: _debtId,
                contractTerms: _contractTerms,
                listingNonce: _listingNonce,
                termsExpiry: _termsExpiry
            }),
            _borrowerSignature,
            _anzaTokenIndexer.ownerOf
        );

        // Transfer debtIAnzaDebtStorefrontEvents
        _transferDebt(
            _debtId,
            _contractTerms,
            _price,
            _borrower,
            _nonce.listingType
        );

        // Emit refinance purchase event
        emit ListingPurchased(
            msg.sender,
            _debtId,
            uint8(_nonce.listingType),
            _price
        );
    }

    /**
     * Overloaded internal function for transferring debt.
     *
     * @notice This function is overloaded to allow for the transfer of debt
     * without specifying contract terms.
     */
    function _transferDebt(
        uint256 _debtId,
        uint256 _price,
        address _seller,
        ListingType _listingType
    ) internal {
        _transferDebt(_debtId, bytes32(0x00), _price, _seller, _listingType);
    }

    /**
     * Non-primary entrypoint for invoking debt transfer through the treasurer.
     *
     * @param _debtId The debt ID to transfer.
     * @param _contractTerms The contract terms of the debt. This parameter is
     * only used for refinance listings. For other listing types, this parameter
     * should be set to bytes32(0x00).
     * @param _price The price of the listing.
     * @param _seller The seller of the listing.
     * @param _listingType The listing type of the listing.
     *
     * @dev Reverts if the listing type is not a valid.
     *
     * @dev See {LoanTreasurey-executeDebtPurchase},
     * {LoanTreasurey-executeSponsorshipPurchase}, &
     * {LoanTreasurey-executeRefinancePurchase}.
     */
    function _transferDebt(
        uint256 _debtId,
        bytes32 _contractTerms,
        uint256 _price,
        address _seller,
        ListingType _listingType
    ) internal {
        if (_listingType == ListingType.DEBT) {
            (bool _success, ) = loanTreasurer.call{value: _price}(
                abi.encodeWithSignature(
                    "executeDebtPurchase(uint256,address,address)",
                    _debtId,
                    _seller,
                    msg.sender
                )
            );
            require(_success);
        } else if (_listingType == ListingType.SPONSORSHIP) {
            (bool _success, ) = loanTreasurer.call{value: _price}(
                abi.encodeWithSignature(
                    "executeSponsorshipPurchase(uint256,address,address)",
                    _debtId,
                    _seller,
                    msg.sender
                )
            );
            require(_success);
        } else if (_listingType == ListingType.REFINANCE) {
            (bool _success, ) = loanTreasurer.call{value: _price}(
                abi.encodeWithSignature(
                    "executeRefinancePurchase(uint256,address,address,bytes32)",
                    _debtId,
                    _seller,
                    msg.sender,
                    _contractTerms
                )
            );
            require(_success);
        } else {
            revert InvalidListingType();
        }
    }

    /**
     * Private function for verifying the listing nonce has not been used
     * and locking it in the same call.
     *
     * This function is used to prevent reentrancy attacks.
     *
     * @notice It's important to check the msg.sender here to prevent any one
     * loan participant from blocking another's unpublished listings.
     *
     * @param _nonce The nonce to lock.
     *
     * @dev Reverts if the nonce was locked prior.
     */
    function __nonceLocker(Nonce storage _nonce) private {
        // Verify nonce is unused
        if (_nonce.locked && msg.sender == _nonce.publisher)
            revert LockedNonce();

        // Lock nonce
        _nonce.locked = true;
    }
}
