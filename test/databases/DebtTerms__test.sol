// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import "@lending-constants/LoanContractStates.sol";
// import "@custom-errors/StdLoanErrors.sol";

import {DebtTerms} from "@lending-databases/DebtTerms.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {StringUtils} from "@test-utils/test-utils/StringUtils.sol";
import {LoanCodecHarness} from "@test-base/_LoanCodec/LoanCodec__test.sol";

contract DebtTermsHarness is DebtTerms {
    constructor() DebtTerms() {}

    function exposed__setDebtTerms(
        uint256 _debtId,
        bytes32 _packedDebtTerms
    ) public {
        _setDebtTerms(_debtId, _packedDebtTerms);
    }

    /* Abstract functions */
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract DebtTermsInit is Setup {
    DebtTermsHarness public debtTermsHarness;
    LoanCodecHarness public loanCodecHarness;

    function setUp() public virtual override {
        // Deploy DebtTerms
        debtTermsHarness = new DebtTermsHarness();

        // Deploy LoanCodec
        loanCodecHarness = new LoanCodecHarness();

        super.setUp();
    }
}

contract DebtTermsUtils is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function checkLoanTerms(
        LoanCodecHarness _loanCodecHarness,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        uint256 _now,
        ContractTerms memory _contractTerms
    ) public {
        uint8 _expectedLoanState = _contractTerms.gracePeriod == 0
            ? _ACTIVE_STATE_
            : _ACTIVE_GRACE_STATE_;

        checkLoanTerms(
            _loanCodecHarness,
            _debtId,
            _activeLoanIndex,
            _now,
            _expectedLoanState,
            _contractTerms
        );
    }

    function checkLoanTerms(
        LoanCodecHarness _loanCodecHarness,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        uint256 _now,
        uint8 _loanState,
        ContractTerms memory _contractTerms
    ) public {
        // Get the unpacked contract terms.
        assertEq(
            _loanCodecHarness.loanState(_debtId),
            _loanState & 0x0f, // Should only be 4 bits.
            "0 :: loan state does not equal expected loan state."
        );

        assertEq(
            _loanCodecHarness.firInterval(_debtId),
            _contractTerms.firInterval & 0x0f, // Should only be 4 bits.
            "1 :: fir interval does not equal expected fir interval."
        );

        assertEq(
            _loanCodecHarness.fixedInterestRate(_debtId),
            _contractTerms.fixedInterestRate & 0xff, // Should only be 8 bits.
            "2 :: fixed interest rate does not equal expected fixed interest rate."
        );

        assertEq(
            _loanCodecHarness.isFixed(_debtId),
            _contractTerms.isFixed == 0x01 ? 1 : 0, // Should only be 4 bits and only 1 or 0.
            "3 :: is fixed does not equal expected is fixed."
        );

        assertEq(
            _loanCodecHarness.loanLastChecked(_debtId),
            _now + _contractTerms.gracePeriod,
            "4 :: loan last checked does not equal expected loan last checked."
        );

        assertEq(
            _loanCodecHarness.loanStart(_debtId),
            _now + _contractTerms.gracePeriod,
            "5 :: loan start does not equal expected loan start."
        );

        assertEq(
            _loanCodecHarness.loanCommital(_debtId),
            _contractTerms.commital,
            "6 :: loan commital does not equal expected loan commital."
        );

        assertEq(
            _loanCodecHarness.loanClose(_debtId),
            _now + _contractTerms.duration + _contractTerms.gracePeriod,
            "7 :: loan close does not equal expected loan close."
        );

        assertEq(
            _loanCodecHarness.lenderRoyalties(_debtId),
            _contractTerms.lenderRoyalties & 0xff, // Should only be 8 bits.
            "8 :: lender royalties does not equal expected lender royalties."
        );

        assertEq(
            _loanCodecHarness.activeLoanCount(_debtId),
            _activeLoanIndex,
            "9 :: active loan contract does not equal expected active loan contract."
        );
    }
}

contract DebtTermsUnitTest is DebtTermsInit {
    DebtTermsUtils public debtTermsUtils;

    function setUp() public virtual override {
        super.setUp();

        // Deploy DebtTermsUtils
        debtTermsUtils = new DebtTermsUtils();
    }

    /* ----------- DebtTerms.debtTerms() ----------- */
    /**
     * Fuzz test the storage of debt terms for random debt IDs and packed contract
     * terms.
     *
     * @param _debtId The debt ID key to store the debt terms under.
     * @param _packedContractTerms The packed contract terms to store.
     *
     * @dev Full pass if the debt terms are equal to the expected packed contract
     * terms.
     */
    function testDebtTerms__Fuzz_DebtTerms(
        uint256 _debtId,
        bytes32 _packedContractTerms
    ) public {
        debtTermsHarness.exposed__setDebtTerms(_debtId, _packedContractTerms);

        assertEq(
            debtTermsHarness.debtTerms(_debtId),
            _packedContractTerms,
            "0 :: debt terms does not equal expected contract terms."
        );
    }

    /* ----------- DebtTerms getters ----------- */
    /**
     * Fuzz test the debt term indexer getters for random debt IDs and contract
     * terms.
     *
     * @param _debtId The debt ID key to store the debt terms under.
     * @param _contractTerms The contract terms to store.
     *
     * @dev Full pass if the debt term getters return the expected values.
     */
    function testDebtTerm__Fuzz_Getters(
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public {
        // Test overflows in testLoanCodec__Fuzz_ValidateLoanTerms
        _contractTerms.commital = uint8(bound(_contractTerms.commital, 0, 100));
        _contractTerms.lenderRoyalties = uint8(
            bound(_contractTerms.lenderRoyalties, 0, 100)
        );

        uint256 _activeLoanIndex = 1;

        // Pack and store the contract terms.
        uint64 _now = uint64(block.timestamp);
        bytes32 _packedContractTerms = createContractTerms(_contractTerms);
        loanCodecHarness.exposed__setLoanAgreement(
            _now,
            _debtId,
            _activeLoanIndex,
            _packedContractTerms
        );

        // Check the unpacked contract terms.
        debtTermsUtils.checkLoanTerms(
            loanCodecHarness,
            _debtId,
            _activeLoanIndex,
            _now,
            _contractTerms
        );
    }
}
