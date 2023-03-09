// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./token/AnzaERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./abdk-libraries-solidity/ABDKMath64x64.sol";
import {LibOfficerRoles as Roles, LibLoanContractMetadata as Metadata, LibLoanContractInit as Init, LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";
import {LibLoanContractStates as States} from "./utils/LibLoanContractStates.sol";
import "./interfaces/ILoanContract.sol";
import "hardhat/console.sol";

contract LoanContract is
    ILoanContract,
    AccessControl,
    AnzaERC1155URIStorage,
    ERC1155Holder
{
    /* ------------------------------------------------ *
     *                Contract Constants                *
     * ------------------------------------------------ */
    string private constant _TOKEN_NAME_ = "Anza Loan Contract";
    string private constant _TOKEN_SYMBOL_ = "ALC";
    uint256 private constant _SECONDS_PER_YEAR_RATIO_SCALED_ = 3155695200;

    /* ------------------------------------------------ *
     *                  Loan States                     *
     * ------------------------------------------------ */
    uint8 private constant _UNDEFINED_STATE_ = 0;
    uint8 private constant _NONLEVERAGED_STATE_ = 1;
    uint8 private constant _UNSPONSORED_STATE_ = 2;
    uint8 private constant _SPONSORED_STATE_ = 3;
    uint8 private constant _FUNDED_STATE_ = 4;
    uint8 private constant _ACTIVE_GRACE_STATE_ = 5;
    uint8 private constant _ACTIVE_STATE_ = 6;
    uint8 private constant _PAID_STATE_ = 7;
    uint8 private constant _DEFAULT_STATE_ = 8;
    uint8 private constant _COLLECTION_STATE_ = 9;
    uint8 private constant _AUCTION_STATE_ = 10;
    uint8 private constant _AWARDED_STATE_ = 11;
    uint8 private constant _CLOSE_STATE_ = 12;

    /* ------------------------------------------------ *
     *                  Access Roles                    *
     * ------------------------------------------------ */
    bytes32 public constant _BORROWER_TOKEN_ = keccak256("BORROWER_TOKEN");
    bytes32 public constant _LENDER_TOKEN_ = keccak256("LENDER_TOKEN");

    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address public immutable arbiter;

    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    // Mapping from collateral to debt ID
    mapping(address => mapping(uint256 => uint256[])) public debtIds;

    //  > 008 - [0..7]     `loanState`
    //  > 008 - [8..15]    `fixedInterestRate`
    //  > 128 - [16..143]  `principal`
    //  > 032 - [144..175] `loanStart`
    //  > 032 - [176..207] `loanClose`
    //  > 016 - [208..255] unused space
    mapping(uint256 => bytes32) private __packedDebtTerms;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private __owners;

    // Mapping from participant to withdrawable balance
    mapping(address => uint256) private __withdrawableBalance;

    // Count of total inactive/active debts
    uint256 public totalDebts;

    constructor(
        address _admin,
        address _arbiter,
        address _treasurer,
        address _collector,
        string memory _nftsURI,
        string memory _baseURI
    ) AnzaERC1155(_baseURI) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);
        _setRoleAdmin(Roles._COLLECTOR_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, _admin);
        _grantRole(Roles._TREASURER_, _treasurer);
        _grantRole(Roles._COLLECTOR_, _collector);

        arbiter = _arbiter;
        _setBaseURI(_nftsURI);
    }

    function name() public pure returns (string memory) {
        return _TOKEN_NAME_;
    }

    function symbol() public pure returns (string memory) {
        return _TOKEN_SYMBOL_;
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override(AccessControl, ERC1155Receiver, AnzaERC1155)
        returns (bool)
    {
        return
            _interfaceId == type(ILoanContract).interfaceId ||
            AnzaERC1155.supportsInterface(_interfaceId) ||
            ERC1155Receiver.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /*
     * This should report back only the total debt tokens, not the ALC NFTs.
     * TODO: Test
     */
    function debtBalanceOf(
        address _borrower,
        uint256 _debtId
    ) public view returns (uint256) {
        if (_borrower != borrowerOf(_debtId))
            revert InvalidParticipant({account: _borrower});

        return balanceOf(lenderOf(_debtId), (_debtId * 2));
    }

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debtIds[_collateralAddress][_collateralId].length;
    }

    /*
     * TODO: Test
     *
     * Input _contractTerms:
     *  > 008 - [0..7]     `loanState`
     *  > 008 - [8..15]    `fixedInterestRate`
     *  > 128 - [16..143]  `principal`
     *  > 032 - [144..175] `gracePeriod`
     *  > 032 - [176..207] `duration`
     *  > 032 - [208..239] `termsExpiry`
     *  > 016 - [240..255] unused space
     *
     * Saved _contractAgreement:
     *  > 008 - [0..7]     `loanState`
     *  > 008 - [8..15]    `fixedInterestRate`
     *  > 128 - [16..143]  `principal`
     *  > 032 - [144..175] `loanStart`
     *  > 032 - [176..207] `loanClose`
     *  > 016 - [208..255] unused space
     */
    function initLoanContract(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        bytes calldata _borrowerSignature
    ) external payable {
        // Validate borrower participation
        IERC721 _collateralToken = IERC721(_collateralAddress);
        address _borrower = _collateralToken.ownerOf(_collateralId);

        if (
            _borrower !=
            __recoverSigner(
                _contractTerms,
                _collateralAddress,
                _collateralId,
                getCollateralNonce(_collateralAddress, _collateralId),
                _borrowerSignature
            )
        ) revert InvalidParticipant({account: _borrower});

        // Add debt ID to collateral mapping
        debtIds[_collateralAddress][_collateralId].push(totalDebts);
        _setLoanAgreement(_contractTerms);

        // Validate lender funding
        uint256 _principal = principal(totalDebts);
        if (msg.value != _principal) _revert(InsufficientFunds.selector);

        // Transfer collateral to arbiter
        _collateralToken.safeTransferFrom(
            _borrower,
            arbiter,
            _collateralId,
            ""
        );

        // Transfer funds to borrower
        (bool _success, ) = _borrower.call{value: _principal}("");
        if (!_success) revert FailedFundsTransfer();

        // Mint debt ALC debt tokens for borrower and lender
        _mintAnzaBatch(
            [msg.sender, _borrower],
            [totalDebts * 2, (totalDebts * 2) + 1],
            [_principal, 1],
            ""
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateralAddress,
            _collateralId,
            totalDebts
        );

        // Setup for next debt ID
        totalDebts += 1;
    }

    function loanState(
        uint256 _debtId
    ) public view returns (uint256 _loanState) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __loanState;

        assembly {
            __loanState := _contractTerms
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function fixedInterestRate(
        uint256 _debtId
    ) public view returns (uint256 _fixedInterestRate) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __fixedInterestRate;

        assembly {
            mstore(0x02, _contractTerms)
            __fixedInterestRate := mload(0)
        }

        unchecked {
            _fixedInterestRate = __fixedInterestRate;
        }
    }

    function principal(
        uint256 _debtId
    ) public view returns (uint256 _principal) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint128 __principal;

        assembly {
            mstore(0x04, _contractTerms)
            __principal := mload(0)
        }

        unchecked {
            _principal = __principal;
        }
    }

    function loanStart(
        uint256 _debtId
    ) public view returns (uint256 _loanStart) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanStart;

        assembly {
            mstore(0x18, _contractTerms)
            __loanStart := mload(0)
        }

        unchecked {
            _loanStart = __loanStart;
        }
    }

    function loanClose(
        uint256 _debtId
    ) public view returns (uint256 _loanClose) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanClose;

        assembly {
            mstore(0x1c, _contractTerms)
            __loanClose := mload(0)
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return __owners[_tokenId];
    }

    function borrowerOf(uint256 _debtId) public view returns (address) {
        return __owners[(_debtId * 2) + 1];
    }

    function lenderOf(uint256 _debtId) public view returns (address) {
        return __owners[_debtId * 2];
    }

    function depositPayment(uint256 _debtId) external payable {
        uint256 _payment = msg.value;

        // Update lender's withdrawable balance
        __withdrawableBalance[lenderOf(_debtId)] += _payment;

        // Burn ALC debt token
        _burn(msg.sender, (_debtId * 2) + 1, _payment);
    }

    function withdrawPayment(
        uint256 _debtId,
        uint256 _amount
    ) external returns (bool) {
        address _lender = msg.sender;

        if (__withdrawableBalance[_lender] < _amount)
            revert InvalidFundsTransfer({amount: _amount});

        // Update lender's withdrawable balance
        __withdrawableBalance[_lender] -= _amount;

        // Burn ALC lender token
        _burn(_lender, _debtId * 2, _amount);

        // Transfer payment funds to lender
        (bool _success, ) = _lender.call{value: _amount}("");
        require(_success);

        return _success;
    }

    function isApprovedForAll(
        address _account,
        address _operator
    ) public view override returns (bool) {
        if (_operator == address(this)) {
            return true;
        }

        return super.isApprovedForAll(_account, _operator);
    }

    function _setLoanAgreement(bytes32 _contractTerms) internal {
        _checkDuration(_contractTerms);

        bytes32 _loanAgreement;
        uint32 _duration;
        uint32 _loanStart = _toUint32(block.timestamp);

        _contractTerms >>= 16;

        assembly {
            mstore(0x16, _contractTerms)
            _duration := mload(0)

            switch _duration
            case 0 {
                mstore(0x20, _ACTIVE_STATE_)
            }
            default {
                mstore(0x20, _ACTIVE_GRACE_STATE_)
            }

            mstore(0x1e, _contractTerms)
            mstore(0x08, _loanStart)
            mstore(0x04, add(_loanStart, _duration))

            _loanAgreement := mload(0x20)
        }

        __packedDebtTerms[totalDebts] = _loanAgreement;
    }

    function _checkDuration(bytes32 _contractTerms) internal {
        uint32 _duration;
        uint32 _loanStart = _toUint32(block.timestamp);

        assembly {
            mstore(0x18, _contractTerms)
            _duration := mload(0)
        }

        unchecked {
            if (uint256(_duration) + uint256(_loanStart) > type(uint32).max)
                revert OverflowLoanTerm();
        }
    }

    function _setLoanState(uint256 _debtId, uint8 _loanState) internal {
        bytes32 _contractTerms = __packedDebtTerms[_debtId] >> 16;

        assembly {
            mstore(0x20, _loanState)
            mstore(0x1e, _contractTerms)
            _contractTerms := mload(0x20)
        }

        __packedDebtTerms[_debtId] = _contractTerms;
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function _toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    function _setBalanceWithInterest(
        address _participant,
        uint256 _debtId
    ) internal view {
        uint256 _fixedInterestRate = fixedInterestRate(_debtId);
        uint256 _oldBalance = debtBalanceOf(_participant, _debtId);

        uint256 _newBalance = _compound(
            _oldBalance,
            _fixedInterestRate,
            15778476
        );
    }

    function _compound(
        uint _principal,
        uint _ratio,
        uint _n
    ) internal pure returns (uint) {
        return
            ABDKMath64x64.mulu(
                _pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(_ratio, 3155695200)
                    ),
                    _n
                ),
                _principal
            );
    }

    function _pow(int128 _x, uint _n) internal pure returns (int128) {
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

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _afterAnzaTokenTransfer(
        address,
        address from,
        address[2] memory to,
        uint256[2] memory ids,
        uint256[2] memory,
        bytes memory
    ) internal override {
        if (from != address(0)) {
            return;
        }

        // Set token owners
        __owners[ids[0]] = to[0];
        __owners[ids[1]] = to[1];

        // Set token URI
        _setURI(ids[0], Strings.toString(ids[0]));
        _setURI(ids[1], Strings.toString(ids[1]));
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }

    function __recoverSigner(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes memory _signature
    ) private pure returns (address) {
        bytes32 _message = __prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
                )
            )
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
