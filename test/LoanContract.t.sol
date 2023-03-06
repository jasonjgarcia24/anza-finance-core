// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC1155Events} from "./interfaces/IERC1155Events.t.sol";
import {IAccessControlEvents} from "./interfaces/IAccessControlEvents.t.sol";
import {LoanArbiter} from "../contracts/LoanArbiter.sol";
import {LoanContract} from "../contracts/LoanContract.sol";
import {LoanTreasureyPool} from "../contracts/LoanTreasureyPool.sol";
import {DemoToken} from "../contracts/DemoToken.sol";
import {LibLoanContractStates as States} from "../contracts/utils/LibLoanContractStates.sol";
import {LibLoanContractMetadata as Metadata, LibLoanContractSigning as Signing} from "../contracts/libraries/LibLoanContract.sol";

abstract contract LoanContractDeployer is
    Test,
    IERC1155Events,
    IAccessControlEvents
{
    address public admin = vm.envAddress("DEAD_ACCOUNT_KEY_1");
    address public treasurer = vm.envAddress("DEAD_ACCOUNT_KEY_2");
    address public collector = vm.envAddress("DEAD_ACCOUNT_KEY_3");
    address public borrower = vm.envAddress("DEAD_ACCOUNT_KEY_4");
    address public lender = vm.envAddress("DEAD_ACCOUNT_KEY_5");
    address public alt_account = vm.envAddress("DEAD_ACCOUNT_KEY_9");
    string public nftsURI = "https://www.a_base_uri.com/nfts/";
    string public baseURI = "https://www.a_base_uri.com/";

    uint256 public borrowerPrivKey = vm.envUint("DEAD_ACCOUNT_PRIVATE_KEY_4");
    uint256 public lenderPrivKey = vm.envUint("DEAD_ACCOUNT_PRIVATE_KEY_5");
    uint256 public collateralId = 0;

    LoanArbiter public loanArbiter;
    LoanContract public loanContract;
    LoanTreasureyPool public loanTreasurer;
    DemoToken public demoToken;

    function setUp() public virtual {
        loanArbiter = new LoanArbiter(admin, treasurer, collector);

        loanContract = new LoanContract(
            admin,
            address(loanArbiter),
            treasurer,
            collector,
            nftsURI,
            baseURI
        );

        loanTreasurer = new LoanTreasureyPool(address(loanContract));

        vm.startPrank(borrower);
        demoToken = new DemoToken();
        demoToken.approve(address(loanContract), collateralId);
        vm.stopPrank();
    }
}

abstract contract LoanSigned is LoanContractDeployer {
    uint64 public termsExpiry = 1209600; // 2 weeks (seconds)
    uint64 public principal = 32; // ETH
    uint64 public duration = 7257600; // 12 weeks (seconds)
    uint32 public gracePeriod = 604800; // 1 week (seconds)
    uint8 public fixedInterestRate = 5; // 0.05
    uint8 public loanState = 2; // Unsponsored

    uint256 collateralNonce = 12345;
    bytes32 contractTerms;

    bytes public signature;

    function setUp() public virtual override {
        super.setUp();

        uint64 _termsExpiry = termsExpiry;
        uint64 _principal = principal;
        uint64 _duration = duration;
        uint32 _gracePeriod = gracePeriod;
        uint8 _fixedInterestRate = fixedInterestRate;
        uint8 _loanState = loanState;

        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _termsExpiry)
            mstore(0x18, _principal)
            mstore(0x10, _duration)
            mstore(0x08, _gracePeriod)
            mstore(0x04, _fixedInterestRate)
            mstore(0x03, _loanState)
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

abstract contract LoanContractMinter is LoanSigned {
    function setUp() public virtual override {
        super.setUp();

        // Create loan contract
        vm.startPrank(lender);
        (bool success, ) = address(loanContract).call{value: principal}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,uint256,bytes)",
                contractTerms,
                address(demoToken),
                collateralId,
                collateralNonce,
                signature
            )
        );
        require(success);
        vm.stopPrank();
    }
}
