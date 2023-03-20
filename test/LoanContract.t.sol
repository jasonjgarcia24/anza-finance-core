// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC1155Events} from "./interfaces/IERC1155Events.t.sol";
import {IAccessControlEvents} from "./interfaces/IAccessControlEvents.t.sol";
import {LoanCollateralVault} from "../contracts/LoanCollateralVault.sol";
import {LoanContract} from "../contracts/LoanContract.sol";
import {LoanTreasurey} from "../contracts/LoanTreasurey.sol";
import {DemoToken} from "../contracts/DemoToken.sol";
import {AnzaToken} from "../contracts/token/AnzaToken.sol";
import {LibOfficerRoles as Roles} from "../contracts/libraries/LibLoanContract.sol";
import {LibLoanContractStates as States} from "../contracts/utils/LibLoanContractStates.sol";
import {LibLoanContractSigning as Signing} from "../contracts/libraries/LibLoanContract.sol";

abstract contract LoanContractGlobalConstants {
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
    uint8 public constant _PAID_STATE_ = 7;
    uint8 public constant _DEFAULT_STATE_ = 8;
    uint8 public constant _COLLECTION_STATE_ = 9;
    uint8 public constant _AUCTION_STATE_ = 10;
    uint8 public constant _AWARDED_STATE_ = 11;
    uint8 public constant _CLOSE_STATE_ = 12;

    /* ------------------------------------------------ *
     *       Fixed Interest Rate (FIR) Intervals        *
     * ------------------------------------------------ */
    uint256 public constant _SECONDLY_ = 0;
    uint256 public constant _MINUTELY_ = 1;
    uint256 public constant _HOURLY_ = 2;
    uint256 public constant _DAILY_ = 3;
    uint256 public constant _WEEKLY_ = 4;
    uint256 public constant _2_WEEKLY_ = 5;
    uint256 public constant _4_WEEKLY_ = 6;
    uint256 public constant _6_WEEKLY_ = 7;
    uint256 public constant _8_WEEKLY_ = 8;
    uint256 public constant _360_DAILY_ = 9;
    uint256 public constant _365_DAILY_ = 10;

    // Need oracle for correct times
    uint256 public constant _MONTHLY_ = 11;
    uint256 public constant _2_MONTHLY_ = 12;
    uint256 public constant _3_MONTHLY_ = 13;
    uint256 public constant _4_MONTHLY_ = 14;
    uint256 public constant _6_MONTHLY_ = 15;

    /* ------------------------------------------------ *
     *                  Loan Terms                      *
     * ------------------------------------------------ */
    uint8 public constant _LOAN_STATE_ = 2; // Unsponsored
    uint8 public constant _FIR_INTERVAL_ = 9;
    uint8 public constant _FIXED_INTEREST_RATE_ = 10; // 0.05
    uint128 public constant _PRINCIPAL_ = 10; // ETH // 226854911280625642308916404954512140970
    uint32 public constant _GRACE_PERIOD_ = 604800; // 1 week (seconds)
    uint32 public constant _DURATION_ = 60 * 60 * 24 * 360 * 2;
    uint32 public constant _TERMS_EXPIRY_ = 1209600; // 2 weeks (seconds)
    uint256 public constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;

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
     *                    CONSTANTS                     *
     * ------------------------------------------------ */
    string public constant _BASE_URI_ = "https://www.a_base_uri.com/";
    string public baseURI = "https://www.demo_token_metadata_uri.com/";
    uint256 public constant collateralId = 0;

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
        loanContract.setAnzaToken(address(anzaToken));

        vm.stopPrank();

        vm.startPrank(borrower);
        demoToken = new DemoToken();
        demoToken.approve(address(loanContract), collateralId);
        vm.stopPrank();
    }
}

abstract contract LoanSigned is LoanContractDeployer {
    uint256 collateralNonce = 0;
    bytes32 contractTerms;

    bytes public signature;

    function setUp() public virtual override {
        super.setUp();

        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1f, _FIR_INTERVAL_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1b, _PRINCIPAL_)
            mstore(0x0b, _GRACE_PERIOD_)
            mstore(0x07, _DURATION_)
            mstore(0x03, _TERMS_EXPIRY_)

            _contractTerms := mload(0x20)
        }

        contractTerms = _contractTerms;

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        signature = abi.encodePacked(r, s, v);
    }
}

abstract contract LoanContractSubmitted is LoanSigned {
    function setUp() public virtual override {
        super.setUp();

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        // Create loan contract
        vm.startPrank(lender);
        (bool success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                contractTerms,
                address(demoToken),
                collateralId,
                signature
            )
        );
        require(success);
        vm.stopPrank();

        // Mint replica token
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();
    }
}
