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
import {LoanContractHarness} from "../Setup.t.sol";
import {LibLoanContractIndexer as Indexer, LibLoanContractInterest as Interest} from "../../contracts/libraries/LibLoanContract.sol";

abstract contract LoanContractSubmitFunctions is
    IERC721Events,
    IERC1155Events,
    LoanSigned
{
    function initLoanContractExpectations(
        ContractTerms memory _contractTerms
    ) public returns (bool) {
        LoanContractHarness _loanContractHarness = new LoanContractHarness();

        // Lender royalties revert check
        if (_contractTerms.lenderRoyalties > 100) {
            // vm.expectRevert(
            //     abi.encodeWithSelector(
            //         ILoanCodec.InvalidLoanParameter.selector,
            //         _LENDER_ROYALTIES_ERROR_ID_
            //     )
            // );
            return false;
        }
        // Time expiry revert check
        else if (
            _contractTerms.termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_
        ) {
            // vm.expectRevert(
            //     abi.encodeWithSelector(
            //         ILoanCodec.InvalidLoanParameter.selector,
            //         _TIME_EXPIRY_ERROR_ID_
            //     )
            // );
            return false;
        }
        // Duration revert check
        else if (
            _contractTerms.duration == 0 ||
            (block.timestamp +
                uint256(_contractTerms.duration) +
                uint256(_contractTerms.gracePeriod)) >
            type(uint32).max
        ) {
            // vm.expectRevert(
            //     abi.encodeWithSelector(
            //         ILoanCodec.InvalidLoanParameter.selector,
            //         _DURATION_ERROR_ID_
            //     )
            // );
            return false;
        }
        // Principal revert check
        else if (_contractTerms.principal == 0) {
            // vm.expectRevert(
            //     abi.encodeWithSelector(
            //         ILoanCodec.InvalidLoanParameter.selector,
            //         _PRINCIPAL_ERROR_ID_
            //     )
            // );
            return false;
        }
        // FIR interval revert check
        else if (_contractTerms.firInterval > 15) {
            // vm.expectRevert(
            //     abi.encodeWithSelector(
            //         ILoanCodec.InvalidLoanParameter.selector,
            //         _FIR_INTERVAL_ERROR_ID_
            //     )
            // );
            return false;
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
                return true;
            } catch (bytes memory) {
                // console.logBytes(err);

                // vm.expectRevert(
                //     abi.encodeWithSelector(
                //         ILoanCodec.InvalidLoanParameter.selector,
                //         _FIXED_INTEREST_RATE_ERROR_ID_
                //     )
                // );
                return false;
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
        address _borrower,
        address _lender,
        uint256 _debtId
    ) public {
        IAnzaToken _anzaToken = IAnzaToken(_anzaTokenAddress);
        uint256 _borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);

        assertEq(
            _anzaToken.borrowerTokenId(_debtId),
            _borrowerTokenId,
            "Invalid borrower token ID"
        );
        assertEq(
            _anzaToken.lenderTokenId(_debtId),
            _lenderTokenId,
            "Invalid lender token ID"
        );
        assertEq(
            _anzaToken.borrowerOf(_debtId),
            _borrower,
            "Invalid borrower account."
        );
        assertEq(
            _anzaToken.lenderOf(_debtId),
            _lender,
            "Invalid lender account."
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
        if (loanContract.totalDebts() == 0) {
            return;
        }

        // Verify balance of borrower token is 1
        uint256 _borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        assertEq(anzaToken.balanceOf(borrower, _borrowerTokenId), 1);

        // // Mint replica token
        // vm.deal(borrower, 1 ether);
        // vm.startPrank(borrower);
        // loanContract.mintReplica(_debtId);
        // vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            _debtId,
            _contractTerms.gracePeriod == 0
                ? _ACTIVE_STATE_
                : _ACTIVE_GRACE_STATE_,
            _contractTerms
        );

        // Verify loan participants
        assertEq(
            anzaToken.lenderOf(_debtId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _contractTerms.principal);

        // Verify token balances
        verifyTokenBalances(_debtId, _contractTerms.principal);

        // Minted lender NFT should have debt token URI
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
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

    function testLoanContractSubmission__Pass() public {}

    function testLoanContractSubmission__BasicLenderSubmitProposal() public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0, "0 :: no debts should exist.");

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

        bool _expectedSuccess = initLoanContractExpectations(_contractTerms);

        bool _success = createLoanContract(
            collateralId,
            _collateralNonce,
            _contractTerms
        );
        if (!_success && !_expectedSuccess) return;
        require(_success, "1 :: loan contract creation failed.");

        _debtId = loanContract.totalDebts();
        verifyPostContractInit(_debtId, _contractTerms);
    }
}

contract LoanContractFuzzSubmit is LoanContractSubmitFunctions {
    function setUp() public virtual override {
        super.setUp();
    }

    function testLoanContractSubmission__AnyLenderRoyaltiesSubmitProposal(
        uint8 _lenderRoyalties
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _lenderRoyalties
            })
        );
    }

    function testLoanContractSubmission__AnyTermsExpirySubmitProposal(
        uint32 _termsExpiry
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _termsExpiry,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
    }

    function testLoanContractSubmission__AnyDurationSubmitProposal(
        uint32 _duration
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _duration,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
    }

    function testLoanContractSubmission__AnyGracePeriodSubmitProposal(
        uint32 _gracePeriod
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _GRACE_PERIOD_,
                gracePeriod: _gracePeriod,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
    }

    function testLoanContractSubmission__AnyPrincipalSubmitProposal(
        uint128 _principal
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: uint256(_principal),
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
    }

    function testLoanContractSubmission__AnyFixedInterestRateSubmitProposal(
        uint8 _fixedInterestRate
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            ContractTerms({
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _fixedInterestRate,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
    }

    function testLoanContractSubmission__AnyFirIntervalSubmitProposal(
        uint8 _firInterval
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            ContractTerms({
                firInterval: _firInterval,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                isFixed: _IS_FIXED_,
                commital: _COMMITAL_,
                principal: _PRINCIPAL_,
                gracePeriod: _GRACE_PERIOD_,
                duration: _DURATION_,
                termsExpiry: _TERMS_EXPIRY_,
                lenderRoyalties: _LENDER_ROYALTIES_
            })
        );
    }

    function testLoanContractSubmission__AnyContractTermsSubmitProposal(
        ContractTerms memory _contractTerms
    ) public {
        _testLoanContractSubmission__AnyContractTermsSubmitProposal(
            _contractTerms
        );
    }

    function _testLoanContractSubmission__AnyContractTermsSubmitProposal(
        ContractTerms memory _contractTerms
    ) internal {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0, "0 :: no debts should exist.");

        uint256 _collateralNonce = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        bool _expectedSuccess = initLoanContractExpectations(_contractTerms);

        bool _success = createLoanContract(
            collateralId,
            _collateralNonce,
            _contractTerms
        );
        if (!_success && !_expectedSuccess) return;
        require(_success, "1 :: loan contract creation failed.");

        _debtId = loanContract.totalDebts();
        verifyPostContractInit(_debtId, _contractTerms);
    }
}
