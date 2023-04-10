// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC1155Events} from "./interfaces/IERC1155Events.t.sol";
import {IAccessControlEvents} from "./interfaces/IAccessControlEvents.t.sol";
import {ILoanCollateralVault} from "../contracts/interfaces/ILoanCollateralVault.sol";
import {LoanContract} from "../contracts/LoanContract.sol";
import {LoanCollateralVault} from "../contracts/LoanCollateralVault.sol";
import {LoanTreasurey} from "../contracts/LoanTreasurey.sol";
import {DemoToken} from "../contracts/utils/DemoToken.sol";
import {AnzaToken} from "../contracts/token/AnzaToken.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractSigning as Signing} from "../contracts/libraries/LibLoanContract.sol";
import "../contracts/libraries/LibLoanContractConstants.sol";

error TryCatchErr(bytes err);

abstract contract Utils {
    /* ------------------------------------------------ *
     *                  Loan Terms                      *
     * ------------------------------------------------ */
    uint8 public constant _FIR_INTERVAL_ = 14;
    uint8 public constant _FIXED_INTEREST_RATE_ = 10; // 0.05
    uint128 public constant _PRINCIPAL_ = 10; // ETH // 226854911280625642308916404954512140970
    uint32 public constant _GRACE_PERIOD_ = 60 * 60 * 24 * 7; // 604800 (1 week)
    uint32 public constant _DURATION_ = 60 * 60 * 24 * 360 * 2; // 62208000 (2 years)
    uint32 public constant _TERMS_EXPIRY_ = 60 * 60 * 24 * 7 * 2; // 1209600 (2 weeks)
    uint8 public constant _LENDER_ROYALTIES_ = 25; // 0.25
    // To calc max price of loan with compounding interest:
    // principal = 10
    // fixedInterestRate = 5
    // duration = 62208000
    // firInterval = 60 * 60 * 24
    // compoundingPeriods = 1
    // timePeriodOfLoan = duration / firInterval
    //
    // principal * (1 + (fixedInterestRate/100 / compoundingPeriods)) ^ (compoundingPeriods * timePeriodOfLoan)
    // 10 * (1 + (0.05 / 1)) ** (1 * 720)

    uint8 public constant _ALT_FIR_INTERVAL_ = 14;
    uint8 public constant _ALT_FIXED_INTEREST_RATE_ = 5; // 0.05
    uint128 public constant _ALT_PRINCIPAL_ = 4; // ETH // 226854911280625642308916404954512140970
    uint32 public constant _ALT_GRACE_PERIOD_ = 60 * 60 * 24 * 5; // 604800 (5 days)
    uint32 public constant _ALT_DURATION_ = 60 * 60 * 24 * 360 * 1; // 62208000 (1 year)
    uint32 public constant _ALT_TERMS_EXPIRY_ = 60 * 60 * 24 * 4; // 1209600 (4 days)
    uint8 public constant _ALT_LENDER_ROYALTIES_ = 10; // 0.10

    /* ------------------------------------------------ *
     *                    CONSTANTS                     *
     * ------------------------------------------------ */
    string public constant _BASE_URI_ = "https://www.a_base_uri.com/";
    string public baseURI = "https://www.demo_token_metadata_uri.com/";
    uint256 public constant collateralId = 3;

    function getTokenURI(uint256 _tokenId) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _BASE_URI_,
                    "debt-token/",
                    Strings.toString(_tokenId)
                )
            );
    }

    function getAccessControlFailMsg(
        bytes32 _role,
        address _account
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(_account), 20),
                    " is missing role ",
                    Strings.toHexString(uint256(_role), 32)
                )
            );
    }
}

contract LoanContractHarness is LoanContract {
    constructor() LoanContract(address(0)) {}

    /* ------------------------------------------------ *
     *                Contract Constants                *
     * ------------------------------------------------ */
    function exposed__SECONDS_PER_24_MINUTES_RATIO_SCALED_()
        public
        pure
        returns (uint256)
    {
        return _SECONDS_PER_24_MINUTES_RATIO_SCALED_;
    }

    function exposed__UINT32_MAX_() public pure returns (uint256) {
        return _UINT32_MAX_;
    }

    /* ------------------------------------------------ *
     *                  Loan States                     *
     * ------------------------------------------------ */
    function exposed__UNDEFINED_STATE_() public pure returns (uint8) {
        return _UNDEFINED_STATE_;
    }

    function exposed__NONLEVERAGED_STATE_() public pure returns (uint8) {
        return _NONLEVERAGED_STATE_;
    }

    function exposed__UNSPONSORED_STATE_() public pure returns (uint8) {
        return _UNSPONSORED_STATE_;
    }

    function exposed__SPONSORED_STATE_() public pure returns (uint8) {
        return _SPONSORED_STATE_;
    }

    function exposed__FUNDED_STATE_() public pure returns (uint8) {
        return _FUNDED_STATE_;
    }

    function exposed__ACTIVE_GRACE_STATE_() public pure returns (uint8) {
        return _ACTIVE_GRACE_STATE_;
    }

    function exposed__ACTIVE_STATE_() public pure returns (uint8) {
        return _ACTIVE_STATE_;
    }

    function exposed__DEFAULT_STATE_() public pure returns (uint8) {
        return _DEFAULT_STATE_;
    }

    function exposed__COLLECTION_STATE_() public pure returns (uint8) {
        return _COLLECTION_STATE_;
    }

    function exposed__AUCTION_STATE_() public pure returns (uint8) {
        return _AUCTION_STATE_;
    }

    function exposed__AWARDED_STATE_() public pure returns (uint8) {
        return _AWARDED_STATE_;
    }

    function exposed__PAID_PENDING_STATE_() public pure returns (uint8) {
        return _PAID_PENDING_STATE_;
    }

    function exposed__CLOSE_STATE_() public pure returns (uint8) {
        return _CLOSE_STATE_;
    }

    function exposed__PAID_STATE_() public pure returns (uint8) {
        return _PAID_STATE_;
    }

    function exposed__CLOSE_DEFAULT_STATE_() public pure returns (uint8) {
        return _CLOSE_DEFAULT_STATE_;
    }

    /* ------------------------------------------------ *
     *       Fixed Interest Rate (FIR) Intervals        *
     * ------------------------------------------------ */
    function exposed__SECONDLY_() public pure returns (uint8) {
        return _SECONDLY_;
    }

    function exposed__MINUTELY_() public pure returns (uint8) {
        return _MINUTELY_;
    }

    function exposed__HOURLY_() public pure returns (uint8) {
        return _HOURLY_;
    }

    function exposed__DAILY_() public pure returns (uint8) {
        return _DAILY_;
    }

    function exposed__WEEKLY_() public pure returns (uint8) {
        return _WEEKLY_;
    }

    function exposed__2_WEEKLY_() public pure returns (uint8) {
        return _2_WEEKLY_;
    }

    function exposed__4_WEEKLY_() public pure returns (uint8) {
        return _4_WEEKLY_;
    }

    function exposed__6_WEEKLY_() public pure returns (uint8) {
        return _6_WEEKLY_;
    }

    function exposed__8_WEEKLY_() public pure returns (uint8) {
        return _8_WEEKLY_;
    }

    function exposed__MONTHLY_() public pure returns (uint8) {
        return _MONTHLY_;
    }

    function exposed__2_MONTHLY_() public pure returns (uint8) {
        return _2_MONTHLY_;
    }

    function exposed__3_MONTHLY_() public pure returns (uint8) {
        return _3_MONTHLY_;
    }

    function exposed__4_MONTHLY_() public pure returns (uint8) {
        return _4_MONTHLY_;
    }

    function exposed__6_MONTHLY_() public pure returns (uint8) {
        return _6_MONTHLY_;
    }

    function exposed__360_DAILY_() public pure returns (uint8) {
        return _360_DAILY_;
    }

    function exposed__ANNUALLY_() public pure returns (uint8) {
        return _ANNUALLY_;
    }

    /* ------------------------------------------------ *
     *               FIR Interval Multipliers           *
     * ------------------------------------------------ */
    function exposed__SECONDLY_MULTIPLIER_() public pure returns (uint256) {
        return _SECONDLY_MULTIPLIER_;
    }

    function exposed__MINUTELY_MULTIPLIER_() public pure returns (uint256) {
        return _MINUTELY_MULTIPLIER_;
    }

    function exposed__HOURLY_MULTIPLIER_() public pure returns (uint256) {
        return _HOURLY_MULTIPLIER_;
    }

    function exposed__DAILY_MULTIPLIER_() public pure returns (uint256) {
        return _DAILY_MULTIPLIER_;
    }

    function exposed__WEEKLY_MULTIPLIER_() public pure returns (uint256) {
        return _WEEKLY_MULTIPLIER_;
    }

    function exposed__2_WEEKLY_MULTIPLIER_() public pure returns (uint256) {
        return _2_WEEKLY_MULTIPLIER_;
    }

    function exposed__4_WEEKLY_MULTIPLIER_() public pure returns (uint256) {
        return _4_WEEKLY_MULTIPLIER_;
    }

    function exposed__6_WEEKLY_MULTIPLIER_() public pure returns (uint256) {
        return _6_WEEKLY_MULTIPLIER_;
    }

    function exposed__8_WEEKLY_MULTIPLIER_() public pure returns (uint256) {
        return _8_WEEKLY_MULTIPLIER_;
    }

    function exposed__360_DAILY_MULTIPLIER_() public pure returns (uint256) {
        return _360_DAILY_MULTIPLIER_;
    }

    /* ------------------------------------------------ *
     *           Packed Debt Term Mappings              *
     * ------------------------------------------------ */
    function exposed__LOAN_STATE_MASK_() public pure returns (uint256) {
        return _LOAN_STATE_MASK_;
    }

    function exposed__LOAN_STATE_MAP_() public pure returns (uint256) {
        return _LOAN_STATE_MAP_;
    }

    function exposed__FIR_INTERVAL_MASK_() public pure returns (uint256) {
        return _FIR_INTERVAL_MASK_;
    }

    function exposed__FIR_INTERVAL_MAP_() public pure returns (uint256) {
        return _FIR_INTERVAL_MAP_;
    }

    function exposed__FIR_MASK_() public pure returns (uint256) {
        return _FIR_MASK_;
    }

    function exposed__FIR_MAP_() public pure returns (uint256) {
        return _FIR_MAP_;
    }

    function exposed__LOAN_START_MASK_() public pure returns (uint256) {
        return _LOAN_START_MASK_;
    }

    function exposed__LOAN_START_MAP_() public pure returns (uint256) {
        return _LOAN_START_MAP_;
    }

    function exposed__LOAN_DURATION_MASK_() public pure returns (uint256) {
        return _LOAN_DURATION_MASK_;
    }

    function exposed__LOAN_DURATION_MAP_() public pure returns (uint256) {
        return _LOAN_DURATION_MAP_;
    }

    function exposed__BORROWER_MASK_() public pure returns (uint256) {
        return _BORROWER_MASK_;
    }

    function exposed__BORROWER_MAP_() public pure returns (uint256) {
        return _BORROWER_MAP_;
    }

    function exposed__LENDER_ROYALTIES_MASK_() public pure returns (uint256) {
        return _LENDER_ROYALTIES_MASK_;
    }

    function exposed__LENDER_ROYALTIES_MAP_() public pure returns (uint256) {
        return _LENDER_ROYALTIES_MAP_;
    }

    function exposed__LOAN_COUNT_MASK_() public pure returns (uint256) {
        return _LOAN_COUNT_MASK_;
    }

    function exposed__LOAN_COUNT_MAP_() public pure returns (uint256) {
        return _LOAN_COUNT_MAP_;
    }

    function exposed__LOAN_STATE_POS_() public pure returns (uint8) {
        return _LOAN_STATE_POS_;
    }

    function exposed__FIR_INTERVAL_POS_() public pure returns (uint8) {
        return _FIR_INTERVAL_POS_;
    }

    function exposed__FIR_POS_() public pure returns (uint8) {
        return _FIR_POS_;
    }

    function exposed__LOAN_START_POS_() public pure returns (uint8) {
        return _LOAN_START_POS_;
    }

    function exposed__LOAN_DURATION_POS_() public pure returns (uint8) {
        return _LOAN_DURATION_POS_;
    }

    function exposed__BORROWER_POS_() public pure returns (uint8) {
        return _BORROWER_POS_;
    }

    function exposed__LENDER_ROYALTIES_POS_() public pure returns (uint8) {
        return _LENDER_ROYALTIES_POS_;
    }

    function exposed__LOAN_COUNT_POS_() public pure returns (uint8) {
        return _LOAN_COUNT_POS_;
    }

    /* ------------------------------------------------ *
     *           Loan Term Standard Errors              *
     * ------------------------------------------------ */
    function exposed__LOAN_STATE_ERROR_ID_() public pure returns (bytes4) {
        return _LOAN_STATE_ERROR_ID_;
    }

    function exposed__FIR_INTERVAL_ERROR_ID_() public pure returns (bytes4) {
        return _FIR_INTERVAL_ERROR_ID_;
    }

    function exposed__DURATION_ERROR_ID_() public pure returns (bytes4) {
        return _DURATION_ERROR_ID_;
    }

    function exposed__PRINCIPAL_ERROR_ID_() public pure returns (bytes4) {
        return _PRINCIPAL_ERROR_ID_;
    }

    function exposed__FIXED_INTEREST_RATE_ERROR_ID_()
        public
        pure
        returns (bytes4)
    {
        return _FIXED_INTEREST_RATE_ERROR_ID_;
    }

    function exposed__GRACE_PERIOD_ERROR_ID_() public pure returns (bytes4) {
        return _GRACE_PERIOD_ERROR_ID_;
    }

    function exposed__TIME_EXPIRY_ERROR_ID_() public pure returns (bytes4) {
        return _TIME_EXPIRY_ERROR_ID_;
    }

    function exposed__LENDER_ROYALTIES_ERROR_ID_()
        public
        pure
        returns (bytes4)
    {
        return _LENDER_ROYALTIES_ERROR_ID_;
    }

    function exposed__getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) public pure returns (uint256) {
        return _getTotalFirIntervals(_firInterval, _seconds);
    }
}

abstract contract Setup is Test, Utils, IERC1155Events, IAccessControlEvents {
    address public admin = vm.envAddress("DEAD_ACCOUNT_KEY_1");
    address public treasurer = vm.envAddress("DEAD_ACCOUNT_KEY_2");
    address public collector = vm.envAddress("DEAD_ACCOUNT_KEY_3");
    address public borrower = vm.envAddress("DEAD_ACCOUNT_KEY_4");
    address public lender = vm.envAddress("DEAD_ACCOUNT_KEY_5");
    address public alt_account = vm.envAddress("DEAD_ACCOUNT_KEY_9");

    uint256 public borrowerPrivKey = vm.envUint("DEAD_ACCOUNT_PRIVATE_KEY_4");
    uint256 public lenderPrivKey = vm.envUint("DEAD_ACCOUNT_PRIVATE_KEY_5");

    LoanCollateralVault public loanCollateralVault;
    LoanContract public loanContract;
    LoanTreasurey public loanTreasurer;
    AnzaToken public anzaToken;
    DemoToken public demoToken;

    uint256 public collateralNonce;
    bytes32 public contractTerms;
    bytes public signature;

    struct ContractTerms {
        uint8 firInterval;
        uint8 fixedInterestRate;
        uint128 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
        uint8 lenderRoyalties;
    }

    function setUp() public virtual {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);

        // Deploy LoanCollateralVault
        loanCollateralVault = new LoanCollateralVault();

        // Deploy LoanContract
        loanContract = new LoanContract(address(loanCollateralVault));

        // Deploy AnzaToken
        anzaToken = new AnzaToken();

        // Deploy LoanTreasurey
        loanTreasurer = new LoanTreasurey(
            address(loanContract),
            address(loanCollateralVault),
            address(anzaToken)
        );

        // Set LoanContract access control roles
        loanContract.grantRole(Roles._TREASURER_, address(loanTreasurer));
        loanContract.grantRole(Roles._COLLECTOR_, collector);

        // Set LoanCollateralVault access control roles
        loanCollateralVault.setLoanContract(address(loanContract));

        loanCollateralVault.grantRole(
            Roles._LOAN_CONTRACT_,
            address(loanContract)
        );

        loanCollateralVault.grantRole(
            Roles._TREASURER_,
            address(loanTreasurer)
        );

        // Set AnzaToken access control roles
        anzaToken.grantRole(Roles._LOAN_CONTRACT_, address(loanContract));
        anzaToken.grantRole(Roles._TREASURER_, address(loanTreasurer));

        // Set AnzaToken address
        loanContract.setLoanTreasurer(address(loanTreasurer));
        loanContract.setAnzaToken(address(anzaToken));

        vm.stopPrank();

        vm.startPrank(borrower);
        demoToken = new DemoToken();
        demoToken.approve(address(loanContract), collateralId);
        demoToken.setApprovalForAll(address(loanContract), true);

        vm.stopPrank();
    }

    function createContractTerms()
        public
        virtual
        returns (bytes32 _contractTerms)
    {
        assembly {
            mstore(0x20, _FIR_INTERVAL_)
            mstore(0x1f, _FIXED_INTEREST_RATE_)
            mstore(0x1d, _PRINCIPAL_)
            mstore(0x0d, _GRACE_PERIOD_)
            mstore(0x09, _DURATION_)
            mstore(0x05, _TERMS_EXPIRY_)
            mstore(0x01, _LENDER_ROYALTIES_)

            _contractTerms := mload(0x20)
        }
    }

    function createContractTerms(
        ContractTerms memory _terms
    ) public pure virtual returns (bytes32 _contractTerms) {
        uint8 _firInterval = _terms.firInterval;
        uint8 _fixedInterestRate = _terms.fixedInterestRate;
        uint128 _principal = _terms.principal;
        uint32 _gracePeriod = _terms.gracePeriod;
        uint32 _duration = _terms.duration;
        uint32 _termsExpiry = _terms.termsExpiry;
        uint8 _lenderRoyalties = _terms.lenderRoyalties;

        assembly {
            mstore(0x20, _firInterval)
            mstore(0x1f, _fixedInterestRate)
            mstore(0x1d, _principal)
            mstore(0x0d, _gracePeriod)
            mstore(0x09, _duration)
            mstore(0x05, _termsExpiry)
            mstore(0x01, _lenderRoyalties)

            _contractTerms := mload(0x20)
        }
    }

    function createContractSignature(
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes32 _contractTerms
    ) public virtual returns (bytes memory _signature) {
        // Create message for signing
        bytes32 _message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    _collateralId,
                    _collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function initLoanContract(
        bytes32 _contractTerms,
        uint256 _principal,
        address _collateralAddress,
        uint256 _collateralId,
        bytes memory _signature
    ) public virtual returns (bool) {
        // Create loan contract
        vm.deal(lender, _principal + (1 ether));
        vm.startPrank(lender);

        (bool _success, ) = address(loanContract).call{value: _principal}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                _collateralAddress,
                _collateralId,
                _signature
            )
        );
        vm.stopPrank();

        return _success;
    }

    function initLoanContract(
        bytes32 _contractTerms,
        uint256 _debtId,
        bytes memory _signature
    ) public virtual returns (bool) {
        // Create loan contract
        vm.startPrank(lender);
        (bool _success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,uint256,bytes)",
                _contractTerms,
                _debtId,
                _signature
            )
        );
        vm.stopPrank();

        return _success;
    }

    function initLoanContract(
        bytes32 _contractTerms,
        uint256 _debtId,
        uint128 _principal,
        bytes memory _signature
    ) public virtual returns (bool) {
        // Create loan contract
        vm.deal(lender, _principal + (1 ether));
        vm.startPrank(lender);
        (bool _success, ) = address(loanContract).call{value: _principal}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,uint256,bytes)",
                _contractTerms,
                _debtId,
                _signature
            )
        );
        vm.stopPrank();

        return _success;
    }

    function createLoanContract(
        uint256 _collateralId
    ) public virtual returns (bool) {
        bytes32 _contractTerms = createContractTerms();

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            _collateralId
        );

        bytes memory _signature = createContractSignature(
            _collateralId,
            _collateralNonce,
            _contractTerms
        );

        return
            initLoanContract(
                _contractTerms,
                _PRINCIPAL_,
                address(demoToken),
                _collateralId,
                _signature
            );
    }

    function createLoanContract(
        uint256 _collateralId,
        ContractTerms memory _terms
    ) public virtual returns (bool) {
        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        return createLoanContract(_collateralId, _collateralNonce, _terms);
    }

    function createLoanContract(
        uint256 _collateralId,
        uint256 _collateralNonce,
        ContractTerms memory _terms
    ) public virtual returns (bool) {
        bytes32 _contractTerms = createContractTerms(_terms);

        bytes memory _signature = createContractSignature(
            _collateralId,
            _collateralNonce,
            _contractTerms
        );

        return
            initLoanContract(
                _contractTerms,
                uint256(_terms.principal),
                address(demoToken),
                _collateralId,
                _signature
            );
    }

    function refinanceDebt(uint256 _debtId) public virtual returns (bool) {
        bytes32 _contractTerms = createContractTerms(
            ContractTerms({
                firInterval: _ALT_FIR_INTERVAL_,
                fixedInterestRate: _ALT_FIXED_INTEREST_RATE_,
                principal: _ALT_PRINCIPAL_,
                gracePeriod: _ALT_GRACE_PERIOD_,
                duration: _ALT_DURATION_,
                termsExpiry: _ALT_TERMS_EXPIRY_,
                lenderRoyalties: _ALT_LENDER_ROYALTIES_
            })
        );

        ILoanCollateralVault.Collateral
            memory _collateral = ILoanCollateralVault(loanCollateralVault)
                .getCollateral(_debtId);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            _collateral.collateralId
        );

        bytes memory _signature = createContractSignature(
            _collateral.collateralId,
            _collateralNonce,
            _contractTerms
        );

        return
            initLoanContract(
                _contractTerms,
                _debtId,
                _ALT_PRINCIPAL_,
                _signature
            );
    }

    function refinanceDebt(
        uint256 _debtId,
        ContractTerms memory _terms
    ) public virtual returns (bool) {
        bytes32 _contractTerms = createContractTerms(_terms);

        ILoanCollateralVault.Collateral
            memory _collateral = ILoanCollateralVault(loanCollateralVault)
                .getCollateral(_debtId);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            _collateral.collateralId
        );

        bytes memory _signature = createContractSignature(
            _collateral.collateralId,
            _collateralNonce,
            _contractTerms
        );

        return
            initLoanContract(
                _contractTerms,
                _debtId,
                _terms.principal,
                _signature
            );
    }

    function mintDemoTokens(uint256 _amount) public virtual {
        vm.startPrank(borrower);
        demoToken.mint(_amount);
        vm.stopPrank();
    }
}
