// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../contracts/domain/LoanContractErrorCodes.sol";
import "../../contracts/domain/LoanContractNumbers.sol";
import "../../contracts/domain/LoanContractStates.sol";

import {IAnzaToken} from "../../contracts/interfaces/IAnzaToken.sol";
import {IERC721Events} from "../interfaces/IERC721Events.t.sol";
import {IERC1155Events} from "../interfaces/IERC1155Events.t.sol";
import {ILoanContract} from "../../contracts/interfaces/ILoanContract.sol";
import {ILoanCodec} from "../../contracts/interfaces/ILoanCodec.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Test, console, LoanSigned} from "../LoanContract.t.sol";
import {Setup, LoanContractHarness} from "../Setup.t.sol";
import {LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer, LibLoanContractInterest as Interest} from "../../contracts/libraries/LibLoanContract.sol";

abstract contract LoanContractSubmitFunctions is
    IERC721Events,
    IERC1155Events,
    LoanSigned
{
    function initLoanContractExpectations(
        uint256 _debtId,
        uint256 _activeLoanIndex,
        ContractTerms memory _contractTerms
    ) public {
        LoanContractHarness _loanContractHarness = new LoanContractHarness();

        // Lender royalties revert check
        if (_contractTerms.lenderRoyalties > 100) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanCodec.InvalidLoanParameter.selector,
                    _LENDER_ROYALTIES_ERROR_ID_
                )
            );
        }
        // Time expiry revert check
        else if (
            _contractTerms.termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_
        ) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanCodec.InvalidLoanParameter.selector,
                    _TIME_EXPIRY_ERROR_ID_
                )
            );
        }
        // Duration revert check
        else if (
            _contractTerms.duration == 0 ||
            (block.timestamp +
                uint256(_contractTerms.duration) +
                uint256(_contractTerms.gracePeriod)) >
            type(uint32).max
        ) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanCodec.InvalidLoanParameter.selector,
                    _DURATION_ERROR_ID_
                )
            );
        }
        // Principal revert check
        else if (_contractTerms.principal == 0) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanCodec.InvalidLoanParameter.selector,
                    _PRINCIPAL_ERROR_ID_
                )
            );
        }
        // FIR interval revert check
        else if (_contractTerms.firInterval > 15) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ILoanCodec.InvalidLoanParameter.selector,
                    _FIR_INTERVAL_ERROR_ID_
                )
            );
        }
        // Fixed interest rate revert check
        else {
            try
                Interest.compoundWithTopoff(
                    _contractTerms.principal,
                    _contractTerms.fixedInterestRate,
                    _loanContractHarness.exposed__getTotalFirIntervals(
                        _contractTerms.firInterval,
                        _contractTerms.duration
                    )
                )
            returns (uint256) {
                // No errors expected

                // Collateral transfer submitted
                vm.expectEmit(true, true, true, true, address(demoToken));
                emit Transfer(borrower, address(collateralVault), collateralId);
                // Loan proposal submitted
                vm.expectEmit(true, true, true, true, address(loanContract));
                emit LoanContractInitialized(
                    address(demoToken),
                    collateralId,
                    _debtId,
                    _activeLoanIndex
                );
            } catch (bytes memory err) {
                console.logBytes(err);

                vm.expectRevert(
                    abi.encodeWithSelector(
                        ILoanCodec.InvalidLoanParameter.selector,
                        _FIXED_INTEREST_RATE_ERROR_ID_
                    )
                );
            }
        }
    }

    function verifyLatestDebtId(
        address _loanContractAddress,
        address _collateralAddress,
        uint256 _debtId
    ) public {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        (uint256 __debtId, , ) = _loanContract.debts(
            _collateralAddress,
            collateralId
        );

        // // Verify debt ID for collateral
        // uint256 numDebtIds = _loanContract.getCollateralNonce(
        //     _collateralAddress,
        //     collateralId
        // );

        assertEq(__debtId, _debtId);
    }

    function verifyLoanAgreementTerms(
        uint256 _debtId,
        uint256 _loanState,
        ContractTerms memory _contractTerms
    ) public {
        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(_debtId),
            _loanState,
            "Invalid loan state"
        );
        assertEq(
            loanContract.firInterval(_debtId),
            _contractTerms.firInterval,
            "Invalid fir interval"
        );
        assertEq(
            loanContract.fixedInterestRate(_debtId),
            _contractTerms.fixedInterestRate,
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.loanClose(_debtId) - loanContract.loanStart(_debtId),
            _contractTerms.duration,
            "Invalid duration"
        );
    }

    function verifyLoanParticipants(
        address _anzaTokenAddress,
        address _lender,
        uint256 _debtId
    ) public {
        IAnzaToken _anzaToken = IAnzaToken(_anzaTokenAddress);
        uint256 lenderTokenId = Indexer.getLenderTokenId(_debtId);

        assertEq(
            _anzaToken.ownerOf(lenderTokenId),
            _lender,
            "Invalid lender token ID"
        );
    }

    function verifyTokenBalances(uint256 _debtId, uint256 _principal) public {
        // Verify token balances
        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(_debtId);

        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _principal;
        balances[1] = 1;

        assertEq(anzaToken.balanceOfBatch(accounts, ids), balances);
    }

    function verifyPostContractInit(
        uint256 _debtId,
        ContractTerms memory _contractTerms
    ) public {
        // Conclude test if initLoanContract reverted
        if (
            loanContract.totalDebts() == 0 ||
            (loanContract.totalDebts() - 1) != _debtId
        ) {
            return;
        }

        // Verify balance of borrower token is zero
        uint256 _borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        assertEq(anzaToken.balanceOf(borrower, _borrowerTokenId), 0);

        // Mint replica token
        vm.deal(borrower, 1 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(_debtId, _ACTIVE_GRACE_STATE_, _contractTerms);

        // Verify loan participants
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _contractTerms.principal);

        // Verify token balances
        verifyTokenBalances(_debtId, _contractTerms.principal);

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }
}

contract LoanContractSubmitTest is LoanContractSubmitFunctions {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPass() public {}

    function testBasicLenderSubmitProposal() public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _contractTerms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: _PRINCIPAL_,
            gracePeriod: _GRACE_PERIOD_,
            duration: _DURATION_,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        initLoanContractExpectations(_debtId + 1, 0, _contractTerms);

        createLoanContract(collateralId, _collateralNonce, _contractTerms);

        verifyPostContractInit(_debtId + 1, _contractTerms);
    }
}

contract LoanContractFuzzSubmit is LoanContractSubmitFunctions {
    function setUp() public virtual override {
        super.setUp();
    }

    function testAnyLenderRoyaltiesSubmitProposal(
        uint8 _lenderRoyalties
    ) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _terms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: _PRINCIPAL_,
            gracePeriod: _GRACE_PERIOD_,
            duration: _DURATION_,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _lenderRoyalties
        });

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }

    function testAnyTermsExpirySubmitProposal(uint32 _termsExpiry) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _terms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: _PRINCIPAL_,
            gracePeriod: _GRACE_PERIOD_,
            duration: _DURATION_,
            termsExpiry: _termsExpiry,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }

    function testAnyDurationSubmitProposal(uint32 _duration) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _terms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: _PRINCIPAL_,
            gracePeriod: _GRACE_PERIOD_,
            duration: _duration,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }

    function testAnyGracePeriodSubmitProposal(uint32 _gracePeriod) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _terms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: _GRACE_PERIOD_,
            gracePeriod: _gracePeriod,
            duration: _DURATION_,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }

    function testAnyPrincipalSubmitProposal(uint128 _principal) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _terms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: uint256(_principal),
            gracePeriod: _GRACE_PERIOD_,
            duration: _DURATION_,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }

    function testAnyFixedInterestRateSubmitProposal(
        uint8 _fixedInterestRate
    ) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _terms = ContractTerms({
            firInterval: _FIR_INTERVAL_,
            fixedInterestRate: _fixedInterestRate,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: _PRINCIPAL_,
            gracePeriod: _GRACE_PERIOD_,
            duration: _DURATION_,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }

    function testAnyFirIntervalSubmitProposal(uint8 _firInterval) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        ContractTerms memory _terms = ContractTerms({
            firInterval: _firInterval,
            fixedInterestRate: _FIXED_INTEREST_RATE_,
            isFixed: _IS_FIXED_,
            commital: _COMMITAL_,
            principal: _PRINCIPAL_,
            gracePeriod: _GRACE_PERIOD_,
            duration: _DURATION_,
            termsExpiry: _TERMS_EXPIRY_,
            lenderRoyalties: _LENDER_ROYALTIES_
        });

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }

    function testAnyContractTermsSubmitProposal(
        ContractTerms memory _terms
    ) public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        bytes32 _contractTerms = createContractTerms(_terms);

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bytes memory _signature = createContractSignature(
            _terms.principal,
            collateralId,
            _collateralNonce,
            _contractTerms
        );

        initLoanContractExpectations(_debtId + 1, 0, _terms);

        initLoanContract(
            _contractTerms,
            _terms.principal,
            address(demoToken),
            collateralId,
            _signature
        );

        verifyPostContractInit(_debtId, _terms);
    }
}
