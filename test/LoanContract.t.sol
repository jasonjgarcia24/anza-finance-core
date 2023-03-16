// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC1155Events} from "./interfaces/IERC1155Events.t.sol";
import {IAccessControlEvents} from "./interfaces/IAccessControlEvents.t.sol";
import {LoanArbiter} from "../contracts/LoanArbiter.sol";
import {LoanContract} from "../contracts/LoanContract.sol";
import {LoanTreasureyPool} from "../contracts/LoanTreasureyPool.sol";
import {DemoToken} from "../contracts/DemoToken.sol";
import {AnzaToken} from "../contracts/token/AnzaToken.sol";
import {LibLoanContractStates as States} from "../contracts/utils/LibLoanContractStates.sol";
import {LibLoanContractMetadata as Metadata, LibLoanContractSigning as Signing} from "../contracts/libraries/LibLoanContract.sol";

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
     *                  Loan Terms                      *
     * ------------------------------------------------ */
    uint8 public constant _LOAN_STATE_ = 2; // Unsponsored
    uint8 public constant _FIXED_INTEREST_RATE_ = 50; // 0.05
    uint128 public constant _PRINCIPAL_ = 32; // ETH
    uint32 public constant _GRACE_PERIOD_ = 604800; // 1 week (seconds)
    uint32 public constant _DURATION_ = 7257600; // 12 weeks (seconds)
    uint32 public constant _TERMS_EXPIRY_ = 1209600; // 2 weeks (seconds)
    uint256 public constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;

    /* ------------------------------------------------ *
     *           Loan Term Standard Errors              *
     * ------------------------------------------------ */
    bytes4 public constant _DURATION_ERROR_ID_ = 0x64757261;
    bytes4 public constant _PRINCIPAL_ERROR_ID_ = 0x7072696e;
    bytes4 public constant _FIXED_INTEREST_RATE_ERROR_ID_ = 0x66697865;
    bytes4 public constant _GRACE_PERIOD_ERROR_ID_ = 0x67726163;
    bytes4 public constant _TIME_EXPIRY_ERROR_ID_ = 0x74696d65;

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

    LoanArbiter public loanArbiter;
    LoanContract public loanContract;
    LoanTreasureyPool public loanTreasurer;
    AnzaToken public anzaToken;
    DemoToken public demoToken;

    function setUp() public virtual {
        loanArbiter = new LoanArbiter(admin, treasurer, collector);

        loanContract = new LoanContract(
            admin,
            address(loanArbiter),
            treasurer,
            collector
        );

        anzaToken = new AnzaToken(address(loanContract));

        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        loanContract.setAnzaToken(address(anzaToken));
        vm.stopPrank();

        // loanTreasurer = new LoanTreasureyPool(address(loanContract));

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
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1c, _PRINCIPAL_)
            mstore(0x0c, _GRACE_PERIOD_)
            mstore(0x08, _DURATION_)
            mstore(0x04, _TERMS_EXPIRY_)

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
    }
}
