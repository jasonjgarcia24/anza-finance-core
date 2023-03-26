// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./token/interfaces/IAnzaToken.sol";
import "./interfaces/IAnzaDebtStorefront.sol";
import "./interfaces/ILoanContract.sol";
import "./interfaces/ILoanTreasurey.sol";
import "./interfaces/ILoanCollateralVault.sol";
import {LibOfficerRoles as Roles, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";

contract AnzaDebtStorefront is ReentrancyGuard, IAnzaDebtStorefront {
    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address public immutable loanContract;
    address public immutable loanTreasurer;
    address public immutable loanCollateralVault;
    address public immutable anzaToken;

    mapping(uint256 => Listing) private __debtListings;
    mapping(address => uint256) private __proceeds;

    constructor(
        address _loanContract,
        address _loanTreasurer,
        address _loanCollateralVault,
        address _anzaToken
    ) {
        loanContract = _loanContract;
        loanTreasurer = _loanTreasurer;
        loanCollateralVault = _loanCollateralVault;
        anzaToken = _anzaToken;
    }

    modifier isDebtOwner(uint256 _debtId) {
        if (
            IAnzaToken(anzaToken).ownerOf(
                Indexer.getBorrowerTokenId(_debtId)
            ) != msg.sender
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

    function buyDebt(
        bytes32 _listingTerms,
        address _collateralAddress,
        uint256 _collateralId,
        bytes calldata _sellerSignature
    ) external payable {
        (bool success, ) = address(this).call{value: msg.value}(
            abi.encodeWithSignature(
                "buyDebt(bytes32,uint256,bytes)",
                _listingTerms,
                ILoanContract(loanContract).getCollateralDebtId(
                    _collateralAddress,
                    _collateralId
                ),
                _sellerSignature
            )
        );
        require(success);
    }

    // @param _listingTerms The keccak256 hash of the IPFS CID.
    function buyDebt(
        bytes32 _listingTerms,
        uint256 _debtId,
        bytes calldata _sellerSignature
    ) public payable isListed(_debtId) nonReentrant {
        IAnzaToken _anzaToken = IAnzaToken(anzaToken);
        address _borrower = _anzaToken.borrowerOf(_debtId);
        uint256 _payment = msg.value;

        if (
            _borrower !=
            __recoverSigner(_listingTerms, _debtId, _payment, _sellerSignature)
        ) revert InvalidListingTerms();

        // Transfer debt
        address _purchaser = msg.sender;
        (bool _success, ) = loanTreasurer.call{value: _payment}(
            abi.encodeWithSignature(
                "buyDebt(uint256,address,address)",
                _debtId,
                _borrower,
                _purchaser
            )
        );
        require(_success);

        emit DebtPurchased(_purchaser, _debtId, _payment);
    }

    function __recoverSigner(
        bytes32 _listingTerms,
        uint256 _debtId,
        uint256 _payment,
        bytes memory _signature
    ) private pure returns (address) {
        bytes32 _message = __prefixed(
            keccak256(abi.encode(_listingTerms, _debtId, _payment))
        );

        (uint8 v, bytes32 r, bytes32 s) = __splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }

    function __prefixed(bytes32 _hash) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function __splitSignature(
        bytes memory _signature
    ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}
