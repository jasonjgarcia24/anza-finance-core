// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC1155Events} from "./interfaces/IERC1155Events.t.sol";
import {IAccessControlEvents} from "./interfaces/IAccessControlEvents.t.sol";
import {LoanContract} from "../contracts/LoanContract.sol";
import {LoanCollateralVault} from "../contracts/LoanCollateralVault.sol";
import {LoanTreasurey} from "../contracts/LoanTreasurey.sol";
import {DemoToken} from "../contracts/utils/DemoToken.sol";
import {AnzaToken} from "../contracts/token/AnzaToken.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractSigning as Signing} from "../contracts/libraries/LibLoanContract.sol";
import "../contracts/libraries/LibLoanContractConstants.sol";

abstract contract Utils {
    /* ------------------------------------------------ *
     *                  Loan Terms                      *
     * ------------------------------------------------ */
    uint8 public constant _FIR_INTERVAL_ = 9;
    uint8 public constant _FIXED_INTEREST_RATE_ = 10; // 0.05
    uint128 public constant _PRINCIPAL_ = 10; // ETH // 226854911280625642308916404954512140970
    uint32 public constant _GRACE_PERIOD_ = 60 * 60 * 24 * 7; // 604800 (1 week)
    uint32 public constant _DURATION_ = 60 * 60 * 24 * 360 * 2; // 62208000 (2 years)
    uint32 public constant _TERMS_EXPIRY_ = 60 * 60 * 24 * 7 * 2; // 1209600 (2 weeks)
    uint8 public constant _LENDER_ROYALTIES_ = 25; // 0.25

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
        returns (uint256)
    {
        return _SECONDS_PER_24_MINUTES_RATIO_SCALED_;
    }

    function exposed__UINT32_MAX_() public returns (uint256) {
        return _UINT32_MAX_;
    }

    /* ------------------------------------------------ *
     *                  Loan States                     *
     * ------------------------------------------------ */
    function exposed__UNDEFINED_STATE_() public returns (uint8) {
        return _UNDEFINED_STATE_;
    }

    function exposed__NONLEVERAGED_STATE_() public returns (uint8) {
        return _NONLEVERAGED_STATE_;
    }

    function exposed__UNSPONSORED_STATE_() public returns (uint8) {
        return _UNSPONSORED_STATE_;
    }

    function exposed__SPONSORED_STATE_() public returns (uint8) {
        return _SPONSORED_STATE_;
    }

    function exposed__FUNDED_STATE_() public returns (uint8) {
        return _FUNDED_STATE_;
    }

    function exposed__ACTIVE_GRACE_STATE_() public returns (uint8) {
        return _ACTIVE_GRACE_STATE_;
    }

    function exposed__ACTIVE_STATE_() public returns (uint8) {
        return _ACTIVE_STATE_;
    }

    function exposed__DEFAULT_STATE_() public returns (uint8) {
        return _DEFAULT_STATE_;
    }

    function exposed__COLLECTION_STATE_() public returns (uint8) {
        return _COLLECTION_STATE_;
    }

    function exposed__AUCTION_STATE_() public returns (uint8) {
        return _AUCTION_STATE_;
    }

    function exposed__AWARDED_STATE_() public returns (uint8) {
        return _AWARDED_STATE_;
    }

    function exposed__PAID_PENDING_STATE_() public returns (uint8) {
        return _PAID_PENDING_STATE_;
    }

    function exposed__CLOSE_STATE_() public returns (uint8) {
        return _CLOSE_STATE_;
    }

    function exposed__PAID_STATE_() public returns (uint8) {
        return _PAID_STATE_;
    }

    function exposed__CLOSE_DEFAULT_STATE_() public returns (uint8) {
        return _CLOSE_DEFAULT_STATE_;
    }

    /* ------------------------------------------------ *
     *       Fixed Interest Rate (FIR) Intervals        *
     * ------------------------------------------------ */
    function exposed__SECONDLY_() public returns (uint8) {
        return _SECONDLY_;
    }

    function exposed__MINUTELY_() public returns (uint8) {
        return _MINUTELY_;
    }

    function exposed__HOURLY_() public returns (uint8) {
        return _HOURLY_;
    }

    function exposed__DAILY_() public returns (uint8) {
        return _DAILY_;
    }

    function exposed__WEEKLY_() public returns (uint8) {
        return _WEEKLY_;
    }

    function exposed__2_WEEKLY_() public returns (uint8) {
        return _2_WEEKLY_;
    }

    function exposed__4_WEEKLY_() public returns (uint8) {
        return _4_WEEKLY_;
    }

    function exposed__6_WEEKLY_() public returns (uint8) {
        return _6_WEEKLY_;
    }

    function exposed__8_WEEKLY_() public returns (uint8) {
        return _8_WEEKLY_;
    }

    function exposed__MONTHLY_() public returns (uint8) {
        return _MONTHLY_;
    }

    function exposed__2_MONTHLY_() public returns (uint8) {
        return _2_MONTHLY_;
    }

    function exposed__3_MONTHLY_() public returns (uint8) {
        return _3_MONTHLY_;
    }

    function exposed__4_MONTHLY_() public returns (uint8) {
        return _4_MONTHLY_;
    }

    function exposed__6_MONTHLY_() public returns (uint8) {
        return _6_MONTHLY_;
    }

    function exposed__360_DAILY_() public returns (uint8) {
        return _360_DAILY_;
    }

    function exposed__ANNUALLY_() public returns (uint8) {
        return _ANNUALLY_;
    }

    /* ------------------------------------------------ *
     *               FIR Interval Multipliers           *
     * ------------------------------------------------ */
    function exposed__SECONDLY_MULTIPLIER_() public returns (uint256) {
        return _SECONDLY_MULTIPLIER_;
    }

    function exposed__MINUTELY_MULTIPLIER_() public returns (uint256) {
        return _MINUTELY_MULTIPLIER_;
    }

    function exposed__HOURLY_MULTIPLIER_() public returns (uint256) {
        return _HOURLY_MULTIPLIER_;
    }

    function exposed__DAILY_MULTIPLIER_() public returns (uint256) {
        return _DAILY_MULTIPLIER_;
    }

    function exposed__WEEKLY_MULTIPLIER_() public returns (uint256) {
        return _WEEKLY_MULTIPLIER_;
    }

    function exposed__2_WEEKLY_MULTIPLIER_() public returns (uint256) {
        return _2_WEEKLY_MULTIPLIER_;
    }

    function exposed__4_WEEKLY_MULTIPLIER_() public returns (uint256) {
        return _4_WEEKLY_MULTIPLIER_;
    }

    function exposed__6_WEEKLY_MULTIPLIER_() public returns (uint256) {
        return _6_WEEKLY_MULTIPLIER_;
    }

    function exposed__8_WEEKLY_MULTIPLIER_() public returns (uint256) {
        return _8_WEEKLY_MULTIPLIER_;
    }

    function exposed__360_DAILY_MULTIPLIER_() public returns (uint256) {
        return _360_DAILY_MULTIPLIER_;
    }

    function exposed__365_DAILY_MULTIPLIER_() public returns (uint256) {
        return _365_DAILY_MULTIPLIER_;
    }

    /* ------------------------------------------------ *
     *           Packed Debt Term Mappings              *
     * ------------------------------------------------ */
    function exposed__LOAN_STATE_MASK_() public returns (uint256) {
        return _LOAN_STATE_MASK_;
    }

    function exposed__LOAN_STATE_MAP_() public returns (uint256) {
        return _LOAN_STATE_MAP_;
    }

    function exposed__FIR_INTERVAL_MASK_() public returns (uint256) {
        return _FIR_INTERVAL_MASK_;
    }

    function exposed__FIR_INTERVAL_MAP_() public returns (uint256) {
        return _FIR_INTERVAL_MAP_;
    }

    function exposed__FIR_MASK_() public returns (uint256) {
        return _FIR_MASK_;
    }

    function exposed__FIR_MAP_() public returns (uint256) {
        return _FIR_MAP_;
    }

    function exposed__LOAN_START_MASK_() public returns (uint256) {
        return _LOAN_START_MASK_;
    }

    function exposed__LOAN_START_MAP_() public returns (uint256) {
        return _LOAN_START_MAP_;
    }

    function exposed__LOAN_DURATION_MASK_() public returns (uint256) {
        return _LOAN_DURATION_MASK_;
    }

    function exposed__LOAN_DURATION_MAP_() public returns (uint256) {
        return _LOAN_DURATION_MAP_;
    }

    function exposed__BORROWER_MASK_() public returns (uint256) {
        return _BORROWER_MASK_;
    }

    function exposed__BORROWER_MAP_() public returns (uint256) {
        return _BORROWER_MAP_;
    }

    function exposed__LENDER_ROYALTIES_MASK_() public returns (uint256) {
        return _LENDER_ROYALTIES_MASK_;
    }

    function exposed__LENDER_ROYALTIES_MAP_() public returns (uint256) {
        return _LENDER_ROYALTIES_MAP_;
    }

    function exposed__LOAN_COUNT_MASK_() public returns (uint256) {
        return _LOAN_COUNT_MASK_;
    }

    function exposed__LOAN_COUNT_MAP_() public returns (uint256) {
        return _LOAN_COUNT_MAP_;
    }

    function exposed__LOAN_STATE_POS_() public returns (uint8) {
        return _LOAN_STATE_POS_;
    }

    function exposed__FIR_INTERVAL_POS_() public returns (uint8) {
        return _FIR_INTERVAL_POS_;
    }

    function exposed__FIR_POS_() public returns (uint8) {
        return _FIR_POS_;
    }

    function exposed__LOAN_START_POS_() public returns (uint8) {
        return _LOAN_START_POS_;
    }

    function exposed__LOAN_DURATION_POS_() public returns (uint8) {
        return _LOAN_DURATION_POS_;
    }

    function exposed__BORROWER_POS_() public returns (uint8) {
        return _BORROWER_POS_;
    }

    function exposed__LENDER_ROYALTIES_POS_() public returns (uint8) {
        return _LENDER_ROYALTIES_POS_;
    }

    function exposed__LOAN_COUNT_POS_() public returns (uint8) {
        return _LOAN_COUNT_POS_;
    }

    /* ------------------------------------------------ *
     *           Loan Term Standard Errors              *
     * ------------------------------------------------ */
    function exposed__LOAN_STATE_ERROR_ID_() public returns (bytes4) {
        return _LOAN_STATE_ERROR_ID_;
    }

    function exposed__FIR_INTERVAL_ERROR_ID_() public returns (bytes4) {
        return _FIR_INTERVAL_ERROR_ID_;
    }

    function exposed__DURATION_ERROR_ID_() public returns (bytes4) {
        return _DURATION_ERROR_ID_;
    }

    function exposed__PRINCIPAL_ERROR_ID_() public returns (bytes4) {
        return _PRINCIPAL_ERROR_ID_;
    }

    function exposed__FIXED_INTEREST_RATE_ERROR_ID_() public returns (bytes4) {
        return _FIXED_INTEREST_RATE_ERROR_ID_;
    }

    function exposed__GRACE_PERIOD_ERROR_ID_() public returns (bytes4) {
        return _GRACE_PERIOD_ERROR_ID_;
    }

    function exposed__TIME_EXPIRY_ERROR_ID_() public returns (bytes4) {
        return _TIME_EXPIRY_ERROR_ID_;
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
        vm.stopPrank();
    }

    function mintDemoTokens(uint256 _amount) public virtual {
        vm.startPrank(borrower);
        demoToken.mint(_amount);
        vm.stopPrank();
    }
}
