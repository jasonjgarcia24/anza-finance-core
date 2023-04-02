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
    address public immutable anzaToken;

    mapping(address => uint256) private __proceeds;

    constructor(
        address _loanContract,
        address _loanTreasurer,
        address _anzaToken
    ) {
        loanContract = _loanContract;
        loanTreasurer = _loanTreasurer;
        anzaToken = _anzaToken;
    }

    function buyDebt(
        bytes32 _listingTerms,
        address _collateralAddress,
        uint256 _collateralId,
        bytes calldata _sellerSignature
    ) external payable {
        (bool success, ) = address(this).call{value: msg.value}(
            abi.encodeWithSignature(
                "executeDebtPurchase(bytes32,uint256,bytes)",
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
    ) public payable nonReentrant {
        IAnzaToken _anzaToken = IAnzaToken(anzaToken);
        address _borrower = _anzaToken.borrowerOf(_debtId);
        uint256 _payment = msg.value;

        if (
            _borrower !=
            __recoverSigner(_listingTerms, _payment, _debtId, _sellerSignature)
        ) revert InvalidListingTerms();

        // Transfer debt
        address _purchaser = msg.sender;
        (bool _success, ) = loanTreasurer.call{value: _payment}(
            abi.encodeWithSignature(
                "executeDebtPurchase(uint256,address,address)",
                _debtId,
                _borrower,
                _purchaser
            )
        );
        require(_success);

        emit DebtPurchased(_purchaser, _debtId, _payment);
    }

    function refinance() public payable nonReentrant {
        
    }

    function __recoverSigner(
        bytes32 _listingTerms,
        uint256 _payment,
        uint256 _debtId,
        bytes memory _signature
    ) private pure returns (address) {
        bytes32 _message = __prefixed(
            keccak256(abi.encode(_listingTerms, _payment, _debtId))
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