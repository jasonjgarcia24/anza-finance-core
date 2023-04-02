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
import {DemoToken} from "../contracts/DemoToken.sol";
import {AnzaToken} from "../contracts/token/AnzaToken.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractSigning as Signing} from "../contracts/libraries/LibLoanContract.sol";

abstract contract LoanContractGlobalConstants {
    /* ------------------------------------------------ *
     *                Contract Constants                *
     * ------------------------------------------------ */
    uint256 public constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;
    uint256 public constant _UINT32_MAX_ = 4294967295;

    /* ------------------------------------------------ *
     *                  Loan States                     *
     * ------------------------------------------------ */
    uint8 public constant _UNDEFINED_STATE_ = 0;
    uint8 public constant _NONLEVERAGED_STATE_ = 1;
    uint8 public constant _UNSPONSORED_STATE_ = 2;
    uint8 public constant _SPONSORED_STATE_ = 3;
    uint8 public constant _FUNDED_STATE_ = 4;
    uint8 public constant _ACTIVE_GRACE_STATE_ = 5;
    uint8 public constant _ACTIVE_STATE_ = 6;
    uint8 public constant _DEFAULT_STATE_ = 7;
    uint8 public constant _COLLECTION_STATE_ = 8;
    uint8 public constant _AUCTION_STATE_ = 9;
    uint8 public constant _AWARDED_STATE_ = 10;
    uint8 public constant _PAID_PENDING_STATE_ = 11;
    uint8 public constant _CLOSE_STATE_ = 12;
    uint8 public constant _PAID_STATE_ = 13;

    /* ------------------------------------------------ *
     *       Fixed Interest Rate (FIR) Intervals        *
     * ------------------------------------------------ */
    uint8 public constant _SECONDLY_ = 0;
    uint8 public constant _MINUTELY_ = 1;
    uint8 public constant _HOURLY_ = 2;
    uint8 public constant _DAILY_ = 3;
    uint8 public constant _WEEKLY_ = 4;
    uint8 public constant _2_WEEKLY_ = 5;
    uint8 public constant _4_WEEKLY_ = 6;
    uint8 public constant _6_WEEKLY_ = 7;
    uint8 public constant _8_WEEKLY_ = 8;
    uint8 public constant _360_DAILY_ = 9;
    uint8 public constant _365_DAILY_ = 10;

    // Need oracle for correct times
    uint8 public constant _MONTHLY_ = 11;
    uint8 public constant _2_MONTHLY_ = 12;
    uint8 public constant _3_MONTHLY_ = 13;
    uint8 public constant _4_MONTHLY_ = 14;
    uint8 public constant _6_MONTHLY_ = 15;

    /* ------------------------------------------------ *
     *               FIR Interval Multipliers           *
     * ------------------------------------------------ */
    uint256 public constant _SECONDLY_MULTIPLIER_ = 1;
    uint256 public constant _MINUTELY_MULTIPLIER_ = 60;
    uint256 public constant _HOURLY_MULTIPLIER_ = 60 * 60;
    uint256 public constant _DAILY_MULTIPLIER_ = 60 * 60 * 24;
    uint256 public constant _WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7;
    uint256 public constant _2_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 2;
    uint256 public constant _4_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 4;
    uint256 public constant _6_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 6;
    uint256 public constant _8_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 8;
    uint256 public constant _360_DAILY_MULTIPLIER_ = 60 * 60 * 24 * 360;
    uint256 public constant _365_DAILY_MULTIPLIER_ = 60 * 60 * 24 * 365;

    /* ------------------------------------------------ *
     *           Packed Debt Term Mappings              *
     * ------------------------------------------------ */
    uint256 public constant _LOAN_STATE_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0;
    uint256 public constant _LOAN_STATE_MAP_ =
        0x000000000000000000000000000000000000000000000000000000000000000F;
    uint256 public constant _FIR_INTERVAL_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0F;
    uint256 public constant _FIR_INTERVAL_MAP_ =
        0x00000000000000000000000000000000000000000000000000000000000000F0;
    uint256 public constant _FIR_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FF;
    uint256 public constant _FIR_MAP_ =
        0x000000000000000000000000000000000000000000000000000000000000FF00;
    uint256 public constant _LOAN_START_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFF;
    uint256 public constant _LOAN_START_MAP_ =
        0x0000000000000000000000000000000000000000000000000000FFFFFFFF0000;
    uint256 public constant _LOAN_DURATION_MASK_ =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFF;
    uint256 public constant _LOAN_DURATION_MAP_ =
        0x00000000000000000000000000000000000000000000FFFFFFFF000000000000;
    uint256 public constant _BORROWER_MASK_ =
        0xFFFF0000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFF;
    uint256 public constant _BORROWER_MAP_ =
        0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000;
    uint256 public constant _CLEANUP_MASK_ = (1 << 240) - 1;

    /* ------------------------------------------------ *
     *           Loan Term Standard Errors              *
     * ------------------------------------------------ */
    bytes4 public constant _LOAN_STATE_ERROR_ID_ = 0xdacce9d3;
    bytes4 public constant _FIR_INTERVAL_ERROR_ID_ = 0xa13e8948;
    bytes4 public constant _DURATION_ERROR_ID_ = 0xfcbf8511;
    bytes4 public constant _PRINCIPAL_ERROR_ID_ = 0x6a901435;
    bytes4 public constant _FIXED_INTEREST_RATE_ERROR_ID_ = 0x8fe03ac3;
    bytes4 public constant _GRACE_PERIOD_ERROR_ID_ = 0xb677e65e;
    bytes4 public constant _TIME_EXPIRY_ERROR_ID_ = 0x67b21a5c;

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

abstract contract LoanContractDeployer is
    Test,
    IERC1155Events,
    IAccessControlEvents,
    LoanContractGlobalConstants
{
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

abstract contract LoanSigned is LoanContractDeployer {
    uint256 public collateralNonce;
    bytes32 public contractTerms;
    bytes public signature;

    function setUp() public virtual override {
        super.setUp();

        collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        contractTerms = createContractTerms();
        signature = createContractSignature(
            collateralId,
            collateralNonce,
            contractTerms
        );
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
        uint256 _collateralId,
        bytes memory _signature
    ) public virtual returns (bool) {
        vm.startPrank(borrower);
        demoToken.approve(address(loanContract), _collateralId);
        vm.stopPrank();

        // Create loan contract
        vm.startPrank(lender);
        (bool _success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                _collateralId,
                _signature
            )
        );
        require(_success);
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

        return initLoanContract(_contractTerms, _collateralId, _signature);
    }
}

abstract contract LoanContractSubmitted is LoanSigned {
    function setUp() public virtual override {
        super.setUp();

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        // Create loan contract
        vm.startPrank(lender);
        (bool _success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                contractTerms,
                address(demoToken),
                collateralId,
                signature
            )
        );
        require(_success);
        vm.stopPrank();

        // Mint replica token
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();
    }

    function mintReplica(uint256 _debtId) public virtual {
        vm.deal(borrower, 1 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();
    }
}

contract LoanContractUnitTest is LoanContractSubmitted {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPass() public {}

    function testCheckLoanRefinanceAllowed() public {}
}
