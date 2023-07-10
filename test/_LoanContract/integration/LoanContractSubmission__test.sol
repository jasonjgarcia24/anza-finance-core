// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

// import {console} from "forge-std/console.sol";
// import {Test} from "forge-std/Test.sol";

// import "@lending-constants/LoanContractNumbers.sol";
// import "@lending-constants/LoanContractStates.sol";
// import "@custom-errors/StdLoanErrors.sol";
// import "@custom-errors/StdCodecErrors.sol";

// import {IAnzaToken} from "@tokens-interfaces/IAnzaToken.sol";
// import {IDebtBook} from "@lending-databases/interfaces/IDebtBook.sol";
// import {ILoanCodec} from "@services-interfaces/ILoanCodec.sol";
// import {InterestCalculator as Interest} from "@lending-libraries/InterestCalculator.sol";

// import {LoanSigned} from "@test-contract/LoanContract__test.sol";
// import {LoanContractHarness} from "@test-base/Setup__test.sol";
// import {IERC721Events} from "@test-utils-interfaces/IERC721Events__test.sol";
// import {IERC1155Events} from "@test-utils-interfaces/IERC1155Events__test.sol";

// import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// abstract contract LoanContractSubmitFunctions is
//     IERC721Events,
//     IERC1155Events,
//     LoanSigned
// {
//     function setUp() public virtual override {
//         super.setUp();
//     }

//     function initLoanContractExpectations(
//         ContractTerms memory _contractTerms
//     ) public returns (bool, bytes memory) {
//         LoanContractHarness _loanContractHarness = new LoanContractHarness();

//         // Principal revert check
//         if (_contractTerms.principal == 0) {
//             return (
//                 false,
//                 abi.encodePacked(
//                     _INVALID_LOAN_PARAMETER_SELECTOR_,
//                     _PRINCIPAL_ERROR_ID_
//                 )
//             );
//         }
//         // Lender royalties revert check
//         else if (_contractTerms.lenderRoyalties > 100) {
//             return (
//                 false,
//                 abi.encodePacked(
//                     _INVALID_LOAN_PARAMETER_SELECTOR_,
//                     _LENDER_ROYALTIES_ERROR_ID_
//                 )
//             );
//         }
//         // Time expiry revert check
//         else if (
//             _contractTerms.termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_
//         ) {
//             return (
//                 false,
//                 abi.encodePacked(
//                     _INVALID_LOAN_PARAMETER_SELECTOR_,
//                     _TERMS_EXPIRY_ERROR_ID_
//                 )
//             );
//         }
//         // Duration revert check
//         else if (
//             _contractTerms.duration == 0 ||
//             (block.timestamp +
//                 uint256(_contractTerms.duration) +
//                 uint256(_contractTerms.gracePeriod)) >
//             type(uint32).max
//         ) {
//             return (
//                 false,
//                 abi.encodePacked(
//                     _INVALID_LOAN_PARAMETER_SELECTOR_,
//                     _DURATION_ERROR_ID_
//                 )
//             );
//         }
//         // FIR interval revert check
//         else if (_contractTerms.firInterval > 15) {
//             return (
//                 false,
//                 abi.encodePacked(
//                     _INVALID_LOAN_PARAMETER_SELECTOR_,
//                     _FIR_INTERVAL_ERROR_ID_
//                 )
//             );
//         }
//         // Fixed interest rate revert check
//         else {
//             try
//                 Interest.compoundWithTopoff(
//                     _contractTerms.principal,
//                     _contractTerms.fixedInterestRate,
//                     _loanContractHarness.exposed__getTotalFirIntervals(
//                         _contractTerms.firInterval,
//                         _contractTerms.duration
//                     )
//                 )
//             returns (uint256) {} catch (bytes memory) {
//                 if (_contractTerms.firInterval != 0)
//                     return (
//                         false,
//                         abi.encodePacked(
//                             _INVALID_LOAN_PARAMETER_SELECTOR_,
//                             _FIXED_INTEREST_RATE_ERROR_ID_
//                         )
//                     );
//             }
//         }

//         return (true, abi.encodePacked());
//     }

//     function compareInitLoanCodecError(
//         bytes memory _error,
//         bytes memory _expectedError
//     ) public {
//         assertEq(
//             bytes8(_error),
//             bytes8(_expectedError),
//             "0 :: compareInitLoanCodecError :: expected fail type mismatch."
//         );
//     }

//     function verifyLatestDebtId(
//         address _loanContractAddress,
//         address _collateralAddress,
//         uint256 _debtId
//     ) public {
//         IDebtBook _loanContract = IDebtBook(_loanContractAddress);
//         (uint256 __debtId, ) = _loanContract.collateralDebtAt(
//             _collateralAddress,
//             collateralId,
//             type(uint256).max
//         );

//         assertEq(
//             __debtId,
//             _debtId,
//             "0 :: verifyLatestDebtId :: Invalid debt ID."
//         );
//     }

//     function verifyLoanAgreementTerms(
//         uint256 _debtId,
//         uint256 _loanState,
//         ContractTerms memory _contractTerms
//     ) public {
//         // Verify loan agreement terms for this debt ID
//         assertEq(
//             loanContract.loanState(_debtId),
//             _loanState,
//             "0 :: verifyLoanAgreementTerms :: Invalid loan state."
//         );
//         assertEq(
//             loanContract.firInterval(_debtId),
//             _contractTerms.firInterval,
//             "1 :: verifyLoanAgreementTerms :: Invalid fir interval."
//         );
//         assertEq(
//             loanContract.fixedInterestRate(_debtId),
//             _contractTerms.fixedInterestRate,
//             "2 :: verifyLoanAgreementTerms :: Invalid fixed interest rate."
//         );
//         assertEq(
//             loanContract.loanClose(_debtId) - loanContract.loanStart(_debtId),
//             _contractTerms.duration,
//             "3 :: verifyLoanAgreementTerms :: Invalid duration."
//         );
//     }

//     function verifyLoanParticipants(
//         address _anzaTokenAddress,
//         address _borrower,
//         address _lender,
//         uint256 _debtId
//     ) public {
//         IAnzaToken _anzaToken = IAnzaToken(_anzaTokenAddress);
//         uint256 _borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
//         uint256 _lenderTokenId = anzaToken.lenderTokenId(_debtId);

//         assertEq(
//             _anzaToken.borrowerTokenId(_debtId),
//             _borrowerTokenId,
//             "0 :: verifyLoanParticipants :: Invalid borrower token ID."
//         );
//         assertEq(
//             _anzaToken.lenderTokenId(_debtId),
//             _lenderTokenId,
//             "1 :: verifyLoanParticipants :: Invalid lender token ID."
//         );
//         assertEq(
//             _anzaToken.borrowerOf(_debtId),
//             _borrower,
//             "2 :: verifyLoanParticipants :: Invalid borrower account.."
//         );
//         assertEq(
//             _anzaToken.lenderOf(_debtId),
//             _lender,
//             "3 :: verifyLoanParticipants :: Invalid lender account.."
//         );
//     }

//     function verifyTokenBalances(uint256 _debtId, uint256 _principal) public {
//         // Verify token balances
//         uint256 borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
//         uint256 lenderTokenId = anzaToken.lenderTokenId(_debtId);

//         address[] memory accounts = new address[](2);
//         accounts[0] = lender;
//         accounts[1] = borrower;

//         uint256[] memory ids = new uint256[](2);
//         ids[0] = lenderTokenId;
//         ids[1] = borrowerTokenId;

//         uint256[] memory balances = new uint256[](2);
//         balances[0] = _principal;
//         balances[1] = 1;

//         assertEq(
//             anzaToken.balanceOfBatch(accounts, ids),
//             balances,
//             "0 :: verifyTokenBalances :: Invalid token balances."
//         );
//     }

//     function verifyPostContractInit(
//         uint256 _debtId,
//         ContractTerms memory _contractTerms
//     ) public {
//         // Conclude test if initLoanContract reverted
//         if (loanContract.totalDebts() == 0) {
//             return;
//         }

//         // Verify balance of borrower token is 1
//         uint256 _borrowerTokenId = anzaToken.borrowerTokenId(_debtId);
//         assertEq(anzaToken.balanceOf(borrower, _borrowerTokenId), 1);

//         // Verify debt ID for collateral
//         verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

//         // Verify loan agreement terms for this debt ID
//         verifyLoanAgreementTerms(
//             _debtId,
//             _contractTerms.gracePeriod == 0
//                 ? _ACTIVE_STATE_
//                 : _ACTIVE_GRACE_STATE_,
//             _contractTerms
//         );

//         // Verify loan participants
//         assertEq(
//             anzaToken.lenderOf(_debtId),
//             lender,
//             "Invalid lender token ID"
//         );

//         // Verify total debt balance
//         assertEq(loanContract.debtBalance(_debtId), _contractTerms.principal);

//         // Verify token balances
//         verifyTokenBalances(_debtId, _contractTerms.principal);

//         // Minted lender NFT should have debt token URI
//         uint256 _lenderTokenId = anzaToken.lenderTokenId(_debtId);
//         assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

//         // Verify debtId is updated at end
//         _debtId = loanContract.totalDebts();
//         assertEq(_debtId, 1);
//     }
// }

// contract LoanContractSubmitTest is LoanContractSubmitFunctions {
//     function setUp() public virtual override {
//         super.setUp();
//     }

//     function testLoanContractSubmission__Pass() public {}

//     function testLoanContractSubmission__BasicLenderSubmitProposal() public {
//         uint256 _debtId = loanContract.totalDebts();
//         assertEq(_debtId, 0, "0 :: no debts should exist.");

//         ContractTerms memory _contractTerms = ContractTerms({
//             firInterval: _FIR_INTERVAL_,
//             fixedInterestRate: _FIXED_INTEREST_RATE_,
//             isFixed: _IS_FIXED_,
//             commitalRatio: _COMMITAL_RATIO_,
//             principal: _PRINCIPAL_,
//             gracePeriod: _GRACE_PERIOD_,
//             duration: _DURATION_,
//             termsExpiry: _TERMS_EXPIRY_,
//             lenderRoyalties: _LENDER_ROYALTIES_
//         });

//         uint256 _collateralNonce = loanContract.collateralNonce(
//             address(demoToken),
//             collateralId
//         );

//         (
//             bool _expectedSuccess,
//             bytes memory _expectedData
//         ) = initLoanContractExpectations(_contractTerms);

//         (bool _success, bytes memory _data) = loanNotaryUtils
//             .createLoanContract(collateralId, _collateralNonce, _contractTerms);

//         // Setting the loan agreement updates the duration to account for the grace
//         // period. We need to do that here too.
//         _contractTerms.duration -= _contractTerms.gracePeriod;

//         compareInitLoanCodecError(_data, _expectedData);
//         if (!_expectedSuccess) return;

//         require(_success, "2 :: loan contract creation failed.");

//         _debtId = loanContract.totalDebts();
//         verifyPostContractInit(_debtId, _contractTerms);
//     }
// }

// contract LoanContractFuzzSubmit is LoanContractSubmitFunctions {
//     function setUp() public virtual override {
//         super.setUp();
//     }

//     function testLoanContractSubmission__AnyLenderRoyaltiesSubmitProposal(
//         uint8 _lenderRoyalties
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             ContractTerms({
//                 firInterval: _FIR_INTERVAL_,
//                 fixedInterestRate: _FIXED_INTEREST_RATE_,
//                 isFixed: _IS_FIXED_,
//                 commitalRatio: _COMMITAL_RATIO_,
//                 principal: _PRINCIPAL_,
//                 gracePeriod: _GRACE_PERIOD_,
//                 duration: _DURATION_,
//                 termsExpiry: _TERMS_EXPIRY_,
//                 lenderRoyalties: _lenderRoyalties
//             })
//         );
//     }

//     function testLoanContractSubmission__AnyTermsExpirySubmitProposal(
//         uint32 _termsExpiry
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             ContractTerms({
//                 firInterval: _FIR_INTERVAL_,
//                 fixedInterestRate: _FIXED_INTEREST_RATE_,
//                 isFixed: _IS_FIXED_,
//                 commitalRatio: _COMMITAL_RATIO_,
//                 principal: _PRINCIPAL_,
//                 gracePeriod: _GRACE_PERIOD_,
//                 duration: _DURATION_,
//                 termsExpiry: _termsExpiry,
//                 lenderRoyalties: _LENDER_ROYALTIES_
//             })
//         );
//     }

//     function testLoanContractSubmission__AnyDurationSubmitProposal(
//         uint32 _duration
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             ContractTerms({
//                 firInterval: _FIR_INTERVAL_,
//                 fixedInterestRate: _FIXED_INTEREST_RATE_,
//                 isFixed: _IS_FIXED_,
//                 commitalRatio: _COMMITAL_RATIO_,
//                 principal: _PRINCIPAL_,
//                 gracePeriod: _GRACE_PERIOD_,
//                 duration: _duration,
//                 termsExpiry: _TERMS_EXPIRY_,
//                 lenderRoyalties: _LENDER_ROYALTIES_
//             })
//         );
//     }

//     function testLoanContractSubmission__AnyGracePeriodSubmitProposal(
//         uint32 _gracePeriod
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             ContractTerms({
//                 firInterval: _FIR_INTERVAL_,
//                 fixedInterestRate: _FIXED_INTEREST_RATE_,
//                 isFixed: _IS_FIXED_,
//                 commitalRatio: _COMMITAL_RATIO_,
//                 principal: _GRACE_PERIOD_,
//                 gracePeriod: _gracePeriod,
//                 duration: _DURATION_,
//                 termsExpiry: _TERMS_EXPIRY_,
//                 lenderRoyalties: _LENDER_ROYALTIES_
//             })
//         );
//     }

//     function testLoanContractSubmission__AnyPrincipalSubmitProposal(
//         uint128 _principal
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             ContractTerms({
//                 firInterval: _FIR_INTERVAL_,
//                 fixedInterestRate: _FIXED_INTEREST_RATE_,
//                 isFixed: _IS_FIXED_,
//                 commitalRatio: _COMMITAL_RATIO_,
//                 principal: uint256(_principal),
//                 gracePeriod: _GRACE_PERIOD_,
//                 duration: _DURATION_,
//                 termsExpiry: _TERMS_EXPIRY_,
//                 lenderRoyalties: _LENDER_ROYALTIES_
//             })
//         );
//     }

//     function testLoanContractSubmission__AnyFixedInterestRateSubmitProposal(
//         uint8 _fixedInterestRate
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             ContractTerms({
//                 firInterval: _FIR_INTERVAL_,
//                 fixedInterestRate: _fixedInterestRate,
//                 isFixed: _IS_FIXED_,
//                 commitalRatio: _COMMITAL_RATIO_,
//                 principal: _PRINCIPAL_,
//                 gracePeriod: _GRACE_PERIOD_,
//                 duration: _DURATION_,
//                 termsExpiry: _TERMS_EXPIRY_,
//                 lenderRoyalties: _LENDER_ROYALTIES_
//             })
//         );
//     }

//     function testLoanContractSubmission__AnyFirIntervalSubmitProposal(
//         uint8 _firInterval
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             ContractTerms({
//                 firInterval: _firInterval,
//                 fixedInterestRate: _FIXED_INTEREST_RATE_,
//                 isFixed: _IS_FIXED_,
//                 commitalRatio: _COMMITAL_RATIO_,
//                 principal: _PRINCIPAL_,
//                 gracePeriod: _GRACE_PERIOD_,
//                 duration: _DURATION_,
//                 termsExpiry: _TERMS_EXPIRY_,
//                 lenderRoyalties: _LENDER_ROYALTIES_
//             })
//         );
//     }

//     function testLoanContractSubmission__AnyContractTermsSubmitProposal(
//         ContractTerms memory _contractTerms
//     ) public {
//         _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//             _contractTerms
//         );
//     }

//     function _testLoanContractSubmission__AnyContractTermsSubmitProposal(
//         ContractTerms memory _contractTerms
//     ) internal {
//         uint256 _debtId = loanContract.totalDebts();
//         assertEq(_debtId, 0, "0 :: no debts should exist.");

//         uint256 _collateralNonce = loanContract.collateralNonce(
//             address(demoToken),
//             collateralId
//         );

//         (
//             bool _expectedSuccess,
//             bytes memory _expectedData
//         ) = initLoanContractExpectations(_contractTerms);

//         (bool _success, bytes memory _data) = loanNotaryUtils
//             .createLoanContract(collateralId, _collateralNonce, _contractTerms);

//         // Setting the loan agreement updates the duration to account for the grace
//         // period. We need to do that here too.
//         _contractTerms.duration -= _contractTerms.gracePeriod;

//         compareInitLoanCodecError(_data, _expectedData);
//         if (!_expectedSuccess) return;

//         require(_success, "1 :: loan contract creation failed.");

//         _debtId = loanContract.totalDebts();
//         verifyPostContractInit(_debtId, _contractTerms);
//     }
// }
