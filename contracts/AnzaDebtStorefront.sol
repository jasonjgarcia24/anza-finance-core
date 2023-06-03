// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DebtNotary} from "./LoanNotary.sol";
import "./interfaces/IAnzaToken.sol";
import "./interfaces/IAnzaDebtStorefront.sol";
import "./interfaces/ILoanContract.sol";
// import "./interfaces/ILoanTreasurey.sol";
// import "./interfaces/ICollateralVault.sol";
import {LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

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

    mapping(address => uint256) private __proceeds;

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
        uint256 _termsExpiry,
        bytes calldata _sellerSignature
    ) public payable nonReentrant {
        uint256 _payment = msg.value;

        address _borrower = _getBorrower(
            _debtId,
            DebtListingParams({
                price: _payment,
                listingTerms: _listingTerms,
                debtId: _debtId,
                termsExpiry: _termsExpiry
            }),
            _sellerSignature,
            IAnzaToken(anzaToken).borrowerOf
        );

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

    function refinance() public payable nonReentrant {}

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
