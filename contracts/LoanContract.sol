// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "./token/interfaces/IAnzaToken.sol";
import "./interfaces/ILoanContract.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./abdk-libraries-solidity/ABDKMath64x64.sol";
import {LibOfficerRoles as Roles} from "./libraries/LibLoanContract.sol";

contract LoanContract is ILoanContract, AccessControl, ERC1155Holder {
    /* ------------------------------------------------ *
     *                Contract Constants                *
     * ------------------------------------------------ */
    uint256 private constant _SECONDS_PER_YEAR_RATIO_SCALED_ = 3155695200;
    uint256 private constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;

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
    uint8 private constant _DEFAULT_STATE_ = 7;
    uint8 private constant _COLLECTION_STATE_ = 8;
    uint8 private constant _AUCTION_STATE_ = 9;
    uint8 private constant _AWARDED_STATE_ = 10;
    uint8 private constant _CLOSE_STATE_ = 11;
    uint8 private constant _PAID_STATE_ = 12;

    /* ------------------------------------------------ *
     *       Fixed Interest Rate (FIR) Intervals        *
     * ------------------------------------------------ */
    //  Need to validate duration > FIR interval
    uint8 private constant _SECONDLY_ = 0;
    uint8 private constant _MINUTELY_ = 1;
    uint8 private constant _HOURLY_ = 2;
    uint8 private constant _DAILY_ = 3;
    uint8 private constant _WEEKLY_ = 4;
    uint8 private constant _2_WEEKLY_ = 5;
    uint8 private constant _4_WEEKLY_ = 6;
    uint8 private constant _6_WEEKLY_ = 7;
    uint8 private constant _8_WEEKLY_ = 8;
    uint8 private constant _MONTHLY_ = 9;
    uint8 private constant _2_MONTHLY_ = 10;
    uint8 private constant _3_MONTHLY_ = 11;
    uint8 private constant _4_MONTHLY_ = 12;
    uint8 private constant _6_MONTHLY_ = 13;
    uint8 private constant _360_DAILY_ = 14;
    uint8 private constant _ANNUALLY_ = 15;

    /* ------------------------------------------------ *
     *           Packed Debt Term Mappings              *
     * ------------------------------------------------ */
    uint256 private constant _LOAN_STATE_MAP_ = 15;
    uint256 private constant _LOAN_STATE_MASK_ = 240;
    uint256 private constant _FIR_MAP_ = 4080;
    uint256 private constant _LOAN_START_MASK_ = 4095;
    uint256 private constant _LOAN_START_MAP_ = 17592186040320;
    uint256 private constant _LOAN_CLOSE_MASK_ = 17592186044415;
    uint256 private constant _LOAN_CLOSE_MAP_ = 75557863708322137374720;
    uint256 private constant _BORROWER_MASK_ = 75557863725914323419135;
    uint256 private constant _BORROWER_MAP_ =
        110427941548649020598956093796432407239217743554650627018874473257369600;

    /* ------------------------------------------------ *
     *           Loan Term Standard Errors              *
     * ------------------------------------------------ */
    bytes4 private constant _DURATION_ERROR_ID_ = 0x64757261;
    bytes4 private constant _PRINCIPAL_ERROR_ID_ = 0x7072696e;
    bytes4 private constant _FIXED_INTEREST_RATE_ERROR_ID_ = 0x66697865;
    bytes4 private constant _GRACE_PERIOD_ERROR_ID_ = 0x67726163;
    bytes4 private constant _TIME_EXPIRY_ERROR_ID_ = 0x74696d65;

    /* ------------------------------------------------ *
     *              Priviledged Accounts                *
     * ------------------------------------------------ */
    address public immutable collateralVault;
    IAnzaToken public anzaToken;

    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    // Mapping from collateral to debt ID
    mapping(address => mapping(uint256 => uint256[])) public debtIds;

    //  > 004 - [0..3]     `loanState`
    //  > 008 - [4..11]    `fixedInterestRate`
    //  > 032 - [12..43]   `loanStart`
    //  > 032 - [44..75]   `loanClose`
    //  > 160 - [76..235]  `borrower`
    //  > 020 - [236..255] extra space
    mapping(uint256 => bytes32) private __packedDebtTerms;

    // Mapping from participant to withdrawable balance
    mapping(address => uint256) public withdrawableBalance;

    // Count of total inactive/active debts
    uint256 public totalDebts;

    constructor(address _collateralVault) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);
        _setRoleAdmin(Roles._COLLECTOR_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, msg.sender);

        collateralVault = _collateralVault;
    }

    function setAnzaToken(
        address _anzaTokenAddress
    ) external onlyRole(Roles._ADMIN_) {
        anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(AccessControl, ERC1155Receiver) returns (bool) {
        return
            _interfaceId == type(ILoanContract).interfaceId ||
            ERC1155Receiver.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /*
     * This should report back only the total debt tokens, not the ALC NFTs.
     * TODO: Test
     */
    function debtBalanceOf(uint256 _debtId) public view returns (uint256) {
        return anzaToken.totalSupply(_debtId * 2);
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
        // _verifyTermsExpiry(_contractTerms);
        // _verifyDuration(_contractTerms);

        // uint256 _principal = msg.value;
        // _verifyPrincipal(_contractTerms, _principal);

        // Verify borrower participation
        IERC721Metadata _collateralToken = IERC721Metadata(_collateralAddress);
        address _borrower = _collateralToken.ownerOf(_collateralId);

        // if (
        //     _borrower !=
        //     __recoverSigner(
        //         _contractTerms,
        //         _collateralAddress,
        //         _collateralId,
        //         getCollateralNonce(_collateralAddress, _collateralId),
        //         _borrowerSignature
        //     )
        // ) revert InvalidParticipant({account: _borrower});

        // // Add debt ID to collateral mapping
        // debtIds[_collateralAddress][_collateralId].push(totalDebts);
        _setLoanAgreement(_borrower, _contractTerms);

        // // Transfer collateral to collateral vault.
        // // The collateral ID and address will be mapped within
        // // the loan collateral vault to the debt ID.
        // _collateralToken.safeTransferFrom(
        //     _borrower,
        //     collateralVault,
        //     _collateralId,
        //     abi.encodePacked(_collateralAddress)
        // );

        // // Transfer funds to borrower
        // (bool _success, ) = _borrower.call{value: _principal}("");
        // if (!_success) revert FailedFundsTransfer();

        // // Mint debt ALC debt tokens for borrower and lender.
        // // This will grant the borrower recal access control
        // // of the collateral following full loan repayment.
        // anzaToken.mint(
        //     msg.sender,
        //     totalDebts * 2,
        //     _principal,
        //     _collateralToken.tokenURI(_collateralId),
        //     abi.encodePacked(_borrower, totalDebts)
        // );

        // // Emit initialization event
        // emit LoanContractInitialized(
        //     _collateralAddress,
        //     _collateralId,
        //     totalDebts
        // );

        // // Setup for next debt ID
        // totalDebts += 1;
    }

    function mintReplica(uint256 _debtId) external {
        address _borrower = msg.sender;

        if (_borrower != borrower(_debtId))
            revert InvalidParticipant(_borrower);

        anzaToken.mint(
            _borrower,
            (_debtId * 2) + 1,
            1,
            "",
            abi.encodePacked(_borrower, _debtId)
        );
    }

    function loanState(
        uint256 _debtId
    ) public view returns (uint256 _loanState) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __loanState;

        assembly {
            __loanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function fixedInterestRate(
        uint256 _debtId
    ) public view returns (uint256 _fixedInterestRate) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        bytes32 __fixedInterestRate;

        assembly {
            __fixedInterestRate := and(_contractTerms, _FIR_MAP_)
        }

        unchecked {
            _fixedInterestRate = uint256(__fixedInterestRate >> 4);
        }
    }

    function loanStart(
        uint256 _debtId
    ) public view returns (uint256 _loanStart) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanStart;

        assembly {
            __loanStart := shr(12, and(_contractTerms, _LOAN_START_MAP_))
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
            __loanClose := shr(44, and(_contractTerms, _LOAN_CLOSE_MAP_))
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function borrower(uint256 _debtId) public view returns (address _borrower) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];

        assembly {
            _borrower := shr(76, and(_contractTerms, _BORROWER_MAP_))
        }
    }

    /*
     * @dev Updates loan state.
    //  */
    function updateLoanState(
        uint256 _debtId
    ) external onlyRole(Roles._TREASURER_) {
        if (checkLoanActive(_debtId) == false)
            revert InactiveLoanState(_debtId);

        // Loan defaulted
        if (_checkLoanExpired(_debtId)) {
            _setLoanState(_debtId, _DEFAULT_STATE_);
        }
        // Loan fully paid off
        else if (anzaToken.totalSupply(_debtId * 2) <= 0) {
            _setLoanState(_debtId, _PAID_STATE_);
        }
        // Loan active and interest compounding
        else if (loanState(_debtId) == _ACTIVE_STATE_) {
            // // Need to mint more debt tokens
            // uint256 _balance = anzaToken.totalSupply(_debtId * 2);
            // uint256 _n = loanClose(_debtId) - block.timestamp; // TODO: THIS ISN'T CORRECT
            // uint256 _newDebt = _balance -
            //     _compound(_balance, fixedInterestRate(_debtId), _n);
            // anzaToken.mint(
            //     anzaToken.lenderOf(_debtId),
            //     totalDebts * 2,
            //     _newDebt,
            //     "",
            //     ""
            // );
        }
        // Loan no longer in grace period
        else if (_checkGracePeriod(_debtId) == false) {
            _setLoanState(_debtId, _ACTIVE_STATE_);
        }
    }

    function checkLoanActive(uint256 _debtId) public view returns (bool) {
        return
            loanState(_debtId) >= _ACTIVE_GRACE_STATE_ &&
            loanState(_debtId) <= _ACTIVE_STATE_;
    }

    function _setLoanAgreement(
        address _borrower,
        bytes32 _contractTerms
    ) internal {
        bytes32 _loanAgreement;
        uint32 _duration;
        uint32 _loanStart = _toUint32(block.timestamp);

        assembly {
            // Get packed duration
            mstore(0x18, _contractTerms)
            _duration := mload(0)
        }

        console.logBytes32(_contractTerms);

        // _contractTerms >>= 4;
        // console.logBytes32(_contractTerms);

        assembly {
            // Pack fixed interest rate and loan state (uint8 and uint4)
            switch _duration
            case 0 {
                mstore(0x20, xor(_contractTerms, _ACTIVE_STATE_))
            }
            default {
                mstore(0x20, xor(_contractTerms, _ACTIVE_GRACE_STATE_))
            }

            // Pack loan start time (uint32)
            mstore(
                0x20,
                xor(
                    and(_LOAN_START_MASK_, mload(0x20)),
                    and(_LOAN_START_MAP_, shl(12, _loanStart))
                )
            )

            // Pack loan close time (uint32)
            mstore(
                0x20,
                xor(
                    and(_LOAN_CLOSE_MASK_, mload(0x20)),
                    and(_LOAN_CLOSE_MAP_, shl(44, add(_loanStart, _duration)))
                )
            )

            // Pack borrower (address)
            mstore(
                0x20,
                xor(
                    and(_BORROWER_MASK_, mload(0x20)),
                    and(_BORROWER_MAP_, shl(76, _borrower))
                )
            )

            _loanAgreement := mload(0x20)
        }

        if (_duration == 0) revert InvalidLoanParameter(_DURATION_ERROR_ID_);

        __packedDebtTerms[totalDebts] = _loanAgreement;
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

    function _checkGracePeriod(uint256 _debtId) internal view returns (bool) {
        return loanStart(_debtId) > block.timestamp;
    }

    function _checkLoanExpired(uint256 _debtId) internal view returns (bool) {
        return
            anzaToken.totalSupply(_debtId * 2) > 0 &&
            loanClose(_debtId) <= block.timestamp;
    }

    function _verifyTermsExpiry(bytes32 _contractTerms) internal pure {
        uint32 _termsExpiry;

        assembly {
            mstore(0x1c, _contractTerms)
            _termsExpiry := mload(0)
        }

        unchecked {
            if (_termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_) {
                revert InvalidLoanParameter(_TIME_EXPIRY_ERROR_ID_);
            }
        }
    }

    function _verifyDuration(bytes32 _contractTerms) internal view {
        uint32 _duration;
        uint32 _loanStart = _toUint32(block.timestamp);

        assembly {
            // Get packed duration
            mstore(0x18, _contractTerms)
            _duration := mload(0)
        }

        unchecked {
            if (
                uint256(_duration) == 0 ||
                uint256(_duration) + uint256(_loanStart) > type(uint32).max
            ) {
                revert InvalidLoanParameter(_DURATION_ERROR_ID_);
            }
        }
    }

    function _verifyPrincipal(
        bytes32 _contractTerms,
        uint256 _amount
    ) internal pure {
        uint128 _principal;

        assembly {
            mstore(0x04, _contractTerms)
            _principal := mload(0)
        }

        if (_principal == 0 || _principal != _amount)
            revert InvalidLoanParameter(_PRINCIPAL_ERROR_ID_);
    }

    function _setBalanceWithInterest(
        address _participant,
        uint256 _debtId
    ) internal view {
        uint256 _fixedInterestRate = fixedInterestRate(_debtId);
        uint256 _oldBalance = debtBalanceOf(_debtId);

        uint256 _newBalance = _compound(
            _oldBalance,
            _fixedInterestRate,
            15778476
        );
    }

    function _compound(
        uint256 _principal,
        uint256 _ratio,
        uint256 _n
    ) internal pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                _pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(
                            _ratio,
                            _SECONDS_PER_YEAR_RATIO_SCALED_
                        )
                    ),
                    _n
                ),
                _principal
            );
    }

    function _pow(int128 _x, uint256 _n) internal pure returns (int128) {
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
