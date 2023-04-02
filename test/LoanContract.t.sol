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
import {LibLoanContractConstants, LibLoanContractStates, LibLoanContractFIRIntervals, LibLoanContractFIRIntervalMultipliers, LibLoanContractPackMappings, LibLoanContractStandardErrors} from "../contracts/libraries/LibLoanContractConstants.sol";
import {Setup, LoanContractHarness} from "./Setup.t.sol";

abstract contract LoanContractDeployer is Setup {
    function setUp() public virtual override {
        super.setUp();
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

contract LoanContractConstantsTest is Test {
    function setUp() public virtual {}

    function testLoanContractConstants() public {
        LoanContractHarness _loanContractHarness = new LoanContractHarness();

        assertEq(
            _loanContractHarness
                .exposed__SECONDS_PER_24_MINUTES_RATIO_SCALED_(),
            LibLoanContractConstants._SECONDS_PER_24_MINUTES_RATIO_SCALED_,
            "_SECONDS_PER_24_MINUTES_RATIO_SCALED_"
        );
        assertEq(
            _loanContractHarness.exposed__UINT32_MAX_(),
            LibLoanContractConstants._UINT32_MAX_,
            "_UINT32_MAX_"
        );

        assertEq(
            _loanContractHarness.exposed__UNDEFINED_STATE_(),
            LibLoanContractStates._UNDEFINED_STATE_,
            "_UNDEFINED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__NONLEVERAGED_STATE_(),
            LibLoanContractStates._NONLEVERAGED_STATE_,
            "_NONLEVERAGED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__UNSPONSORED_STATE_(),
            LibLoanContractStates._UNSPONSORED_STATE_,
            "_UNSPONSORED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__SPONSORED_STATE_(),
            LibLoanContractStates._SPONSORED_STATE_,
            "_SPONSORED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__FUNDED_STATE_(),
            LibLoanContractStates._FUNDED_STATE_,
            "_FUNDED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__ACTIVE_GRACE_STATE_(),
            LibLoanContractStates._ACTIVE_GRACE_STATE_,
            "_ACTIVE_GRACE_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__ACTIVE_STATE_(),
            LibLoanContractStates._ACTIVE_STATE_,
            "_ACTIVE_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__DEFAULT_STATE_(),
            LibLoanContractStates._DEFAULT_STATE_,
            "_DEFAULT_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__COLLECTION_STATE_(),
            LibLoanContractStates._COLLECTION_STATE_,
            "_COLLECTION_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__AUCTION_STATE_(),
            LibLoanContractStates._AUCTION_STATE_,
            "_AUCTION_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__AWARDED_STATE_(),
            LibLoanContractStates._AWARDED_STATE_,
            "_AWARDED_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__PAID_PENDING_STATE_(),
            LibLoanContractStates._PAID_PENDING_STATE_,
            "_PAID_PENDING_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__CLOSE_STATE_(),
            LibLoanContractStates._CLOSE_STATE_,
            "_CLOSE_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__PAID_STATE_(),
            LibLoanContractStates._PAID_STATE_,
            "_PAID_STATE_"
        );
        assertEq(
            _loanContractHarness.exposed__CLOSE_DEFAULT_STATE_(),
            LibLoanContractStates._CLOSE_DEFAULT_STATE_,
            "_CLOSE_DEFAULT_STATE_"
        );

        assertEq(
            _loanContractHarness.exposed__SECONDLY_(),
            LibLoanContractFIRIntervals._SECONDLY_,
            "_SECONDLY_"
        );
        assertEq(
            _loanContractHarness.exposed__MINUTELY_(),
            LibLoanContractFIRIntervals._MINUTELY_,
            "_MINUTELY_"
        );
        assertEq(
            _loanContractHarness.exposed__HOURLY_(),
            LibLoanContractFIRIntervals._HOURLY_,
            "_HOURLY_"
        );
        assertEq(
            _loanContractHarness.exposed__DAILY_(),
            LibLoanContractFIRIntervals._DAILY_,
            "_DAILY_"
        );
        assertEq(
            _loanContractHarness.exposed__WEEKLY_(),
            LibLoanContractFIRIntervals._WEEKLY_,
            "_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__2_WEEKLY_(),
            LibLoanContractFIRIntervals._2_WEEKLY_,
            "_2_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__4_WEEKLY_(),
            LibLoanContractFIRIntervals._4_WEEKLY_,
            "_4_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__6_WEEKLY_(),
            LibLoanContractFIRIntervals._6_WEEKLY_,
            "_6_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__8_WEEKLY_(),
            LibLoanContractFIRIntervals._8_WEEKLY_,
            "_8_WEEKLY_"
        );
        assertEq(
            _loanContractHarness.exposed__MONTHLY_(),
            LibLoanContractFIRIntervals._MONTHLY_,
            "_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__2_MONTHLY_(),
            LibLoanContractFIRIntervals._2_MONTHLY_,
            "_2_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__3_MONTHLY_(),
            LibLoanContractFIRIntervals._3_MONTHLY_,
            "_3_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__4_MONTHLY_(),
            LibLoanContractFIRIntervals._4_MONTHLY_,
            "_4_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__6_MONTHLY_(),
            LibLoanContractFIRIntervals._6_MONTHLY_,
            "_6_MONTHLY_"
        );
        assertEq(
            _loanContractHarness.exposed__360_DAILY_(),
            LibLoanContractFIRIntervals._360_DAILY_,
            "_360_DAILY_"
        );
        assertEq(
            _loanContractHarness.exposed__ANNUALLY_(),
            LibLoanContractFIRIntervals._ANNUALLY_,
            "_ANNUALLY_"
        );

        assertEq(
            _loanContractHarness.exposed__SECONDLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._SECONDLY_MULTIPLIER_,
            "_SECONDLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__MINUTELY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._MINUTELY_MULTIPLIER_,
            "_MINUTELY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__HOURLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._HOURLY_MULTIPLIER_,
            "_HOURLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__DAILY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._DAILY_MULTIPLIER_,
            "_DAILY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._WEEKLY_MULTIPLIER_,
            "_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__2_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._2_WEEKLY_MULTIPLIER_,
            "_2_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__4_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._4_WEEKLY_MULTIPLIER_,
            "_4_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__6_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._6_WEEKLY_MULTIPLIER_,
            "_6_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__8_WEEKLY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._8_WEEKLY_MULTIPLIER_,
            "_8_WEEKLY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__360_DAILY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._360_DAILY_MULTIPLIER_,
            "_360_DAILY_MULTIPLIER_"
        );
        assertEq(
            _loanContractHarness.exposed__365_DAILY_MULTIPLIER_(),
            LibLoanContractFIRIntervalMultipliers._365_DAILY_MULTIPLIER_,
            "_365_DAILY_MULTIPLIER_"
        );

        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_MASK_(),
            LibLoanContractPackMappings._LOAN_STATE_MASK_,
            "_LOAN_STATE_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_MAP_(),
            LibLoanContractPackMappings._LOAN_STATE_MAP_,
            "_LOAN_STATE_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_MASK_(),
            LibLoanContractPackMappings._FIR_INTERVAL_MASK_,
            "_FIR_INTERVAL_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_MAP_(),
            LibLoanContractPackMappings._FIR_INTERVAL_MAP_,
            "_FIR_INTERVAL_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_MASK_(),
            LibLoanContractPackMappings._FIR_MASK_,
            "_FIR_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_MAP_(),
            LibLoanContractPackMappings._FIR_MAP_,
            "_FIR_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_START_MASK_(),
            LibLoanContractPackMappings._LOAN_START_MASK_,
            "_LOAN_START_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_START_MAP_(),
            LibLoanContractPackMappings._LOAN_START_MAP_,
            "_LOAN_START_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_DURATION_MASK_(),
            LibLoanContractPackMappings._LOAN_DURATION_MASK_,
            "_LOAN_DURATION_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_DURATION_MAP_(),
            LibLoanContractPackMappings._LOAN_DURATION_MAP_,
            "_LOAN_DURATION_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__BORROWER_MASK_(),
            LibLoanContractPackMappings._BORROWER_MASK_,
            "_BORROWER_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__BORROWER_MAP_(),
            LibLoanContractPackMappings._BORROWER_MAP_,
            "_BORROWER_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LENDER_ROYALTIES_MASK_(),
            LibLoanContractPackMappings._LENDER_ROYALTIES_MASK_,
            "_LENDER_ROYALTIES_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LENDER_ROYALTIES_MAP_(),
            LibLoanContractPackMappings._LENDER_ROYALTIES_MAP_,
            "_LENDER_ROYALTIES_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_COUNT_MASK_(),
            LibLoanContractPackMappings._LOAN_COUNT_MASK_,
            "_LOAN_COUNT_MASK_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_COUNT_MAP_(),
            LibLoanContractPackMappings._LOAN_COUNT_MAP_,
            "_LOAN_COUNT_MAP_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_POS_(),
            LibLoanContractPackMappings._LOAN_STATE_POS_,
            "_LOAN_STATE_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_POS_(),
            LibLoanContractPackMappings._FIR_INTERVAL_POS_,
            "_FIR_INTERVAL_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_POS_(),
            LibLoanContractPackMappings._FIR_POS_,
            "_FIR_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_START_POS_(),
            LibLoanContractPackMappings._LOAN_START_POS_,
            "_LOAN_START_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_DURATION_POS_(),
            LibLoanContractPackMappings._LOAN_DURATION_POS_,
            "_LOAN_DURATION_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__BORROWER_POS_(),
            LibLoanContractPackMappings._BORROWER_POS_,
            "_BORROWER_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LENDER_ROYALTIES_POS_(),
            LibLoanContractPackMappings._LENDER_ROYALTIES_POS_,
            "_LENDER_ROYALTIES_POS_"
        );
        assertEq(
            _loanContractHarness.exposed__LOAN_COUNT_POS_(),
            LibLoanContractPackMappings._LOAN_COUNT_POS_,
            "_LOAN_COUNT_POS_"
        );

        assertEq(
            _loanContractHarness.exposed__LOAN_STATE_ERROR_ID_(),
            LibLoanContractStandardErrors._LOAN_STATE_ERROR_ID_,
            "_LOAN_STATE_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__FIR_INTERVAL_ERROR_ID_(),
            LibLoanContractStandardErrors._FIR_INTERVAL_ERROR_ID_,
            "_FIR_INTERVAL_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__DURATION_ERROR_ID_(),
            LibLoanContractStandardErrors._DURATION_ERROR_ID_,
            "_DURATION_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__PRINCIPAL_ERROR_ID_(),
            LibLoanContractStandardErrors._PRINCIPAL_ERROR_ID_,
            "_PRINCIPAL_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__FIXED_INTEREST_RATE_ERROR_ID_(),
            LibLoanContractStandardErrors._FIXED_INTEREST_RATE_ERROR_ID_,
            "_FIXED_INTEREST_RATE_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__GRACE_PERIOD_ERROR_ID_(),
            LibLoanContractStandardErrors._GRACE_PERIOD_ERROR_ID_,
            "_GRACE_PERIOD_ERROR_ID_"
        );
        assertEq(
            _loanContractHarness.exposed__TIME_EXPIRY_ERROR_ID_(),
            LibLoanContractStandardErrors._TIME_EXPIRY_ERROR_ID_,
            "_TIME_EXPIRY_ERROR_ID_"
        );
    }
}

contract LoanContractUnitTest is LoanContractSubmitted {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPass() public {}

    function testCheckLoanRefinanceAllowed() public {}
}
