// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./interfaces/IAnzaDebtStorefront.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanCollateralVault.sol";
import {LibOfficerRoles as Roles, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";

contract AnzaDebtStorefront is ReentrancyGuard, IAnzaDebtStorefront {
    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address public immutable loanContract;
    address public immutable loanCollateralVault;
    address public immutable anzaToken;

    mapping(uint256 => Listing) private __debtListings;
    mapping(address => uint256) private __proceeds;

    constructor(
        address _loanContract,
        address _loanCollateralVault,
        address _anzaToken
    ) {
        loanContract = _loanContract;
        loanCollateralVault = _loanCollateralVault;
        anzaToken = _anzaToken;
    }

    modifier isDebtOwner(uint256 _debtId) {
        if (
            IERC721(anzaToken).ownerOf(Indexer.getBorrowerTokenId(_debtId)) !=
            msg.sender
        ) revert InvalidDebtOwner(msg.sender);

        _;
    }

    modifier isNotListed(uint256 _debtId) {
        if (__debtListings[_debtId].price > 0) revert ExistingListing(_debtId);
        _;
    }

    modifier isListed(uint256 _debtId) {
        if (__debtListings[_debtId].price <= 0)
            revert NonExistingListing(_debtId);
        _;
    }

    function listDebt(
        uint256 _debtId,
        uint256 _price
    ) external isDebtOwner(_debtId) isNotListed(_debtId) {
        address _debtOwner = msg.sender;

        // Verify listing price
        if (_price <= 0 || _price > type(uint128).max)
            revert InvalidListingPrice(_price);

        // List debt
        ILoanCollateralVault.Collateral
            memory _collateral = ILoanCollateralVault(loanCollateralVault)
                .getCollateralAt(_debtId);

        __debtListings[_debtId] = Listing({
            price: _price,
            debtOwner: _debtOwner,
            collateralAddress: _collateral.collateralAddress,
            collateralId: _collateral.collateralId,
            debtTerms: ILoanContract(loanContract).getDebtTerms(_debtId)
        });

        emit DebtListed(_debtOwner, _debtId, _price);
    }

    function cancelListing(
        uint256 _debtId
    ) external isDebtOwner(_debtId) isListed(_debtId) {
        delete (__debtListings[_debtId]);
        emit ListingCancelled(msg.sender, _debtId);
    }

    function buyDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) external payable {
        (bool success, ) = address(this).call{value: msg.value}(
            abi.encodeWithSignature(
                "buyDebt(uint256)",
                ILoanContract(loanContract).getCollateralDebtId(
                    _collateralAddress,
                    _collateralId
                )
            )
        );
        require(success);
    }

    function buyDebt(
        uint256 _debtId
    ) public payable isListed(_debtId) nonReentrant {
        Listing memory _debtListing = __debtListings[_debtId];
        uint256 _payment = msg.value;

        if (_payment < _debtListing.price) revert InsufficientPayment(_payment);

        __proceeds[_debtListing.debtOwner] += _payment;

        delete (__debtListings[_debtId]);

        IERC721(anzaToken).safeTransferFrom(
            _debtListing.debtOwner,
            msg.sender,
            Indexer.getBorrowerTokenId(_debtId)
        );

        emit DebtPurchased(msg.sender, _debtId, _debtListing.price);
    }

    function updateListing(
        uint256 _debtId,
        uint256 _newPrice
    ) external isDebtOwner(_debtId) isListed(_debtId) nonReentrant {
        if (_newPrice == 0) revert InvalidListingPrice(_newPrice);

        __debtListings[_debtId].price = _newPrice;

        emit DebtListed(msg.sender, _debtId, _newPrice);
    }

    function withdrawProceeds() external {
        address _payee = msg.sender;
        uint256 _proceeds = __proceeds[_payee];

        if (_proceeds <= 0) revert InsufficientProceeds(_payee);

        __proceeds[_payee] = 0;

        (bool success, ) = payable(_payee).call{value: _proceeds}("");
        require(success, "Transfer failed");
    }

    function getListing(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (Listing memory) {
        return
            getListing(
                ILoanContract(loanContract).getCollateralDebtId(
                    _collateralAddress,
                    _collateralId
                )
            );
    }

    function getListing(uint256 _debtId) public view returns (Listing memory) {
        return __debtListings[_debtId];
    }

    function getProceeds(address _seller) external view returns (uint256) {
        return __proceeds[_seller];
    }
}
