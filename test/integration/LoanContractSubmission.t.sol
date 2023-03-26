// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IAnzaToken} from "../../contracts/token/interfaces/IAnzaToken.sol";
import {IERC1155Events} from "../interfaces/IERC1155Events.t.sol";
import {ILoanContract} from "../../contracts/interfaces/ILoanContract.sol";
import {ILoanContractEvents} from "../interfaces/ILoanContractEvents.t.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Test, console, LoanContractGlobalConstants, LoanContractDeployer, LoanSigned} from "../LoanContract.t.sol";
import {LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "../../contracts/libraries/LibLoanContract.sol";

abstract contract LoanContractSubmitFunctions is
    Test,
    IERC1155Events,
    ILoanContractEvents,
    LoanContractGlobalConstants
{
    struct TestTermsStruct {
        uint8 loanState;
        uint256 firInterval;
        uint8 fixedInterestRate;
        uint128 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
    }

    function initLoanContractExpectations(
        address _loanContractAddress,
        address _lender,
        address _collateralAddress,
        uint256 _debtId,
        uint128 _principal,
        uint32 _duration,
        uint32 _gracePeriod,
        uint32 _termsExpiry
    ) public {
        if (
            _principal != 0 &&
            _duration != 0 &&
            _termsExpiry >= _SECONDS_PER_24_MINUTES_RATIO_SCALED_ &&
            (block.timestamp + uint256(_duration) + uint256(_gracePeriod)) <=
            type(uint32).max
        ) {
            vm.expectEmit(true, true, true, true);
            emit TransferSingle(
                _loanContractAddress,
                address(0),
                _lender,
                (_debtId * 2),
                uint256(_principal)
            );

            // Loan proposal submitted
            vm.expectEmit(true, true, true, true);
            emit LoanContractInitialized(
                _collateralAddress,
                collateralId,
                _debtId
            );
        }

        if (_termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidLoanParameter.selector,
                    _TIME_EXPIRY_ERROR_ID_
                )
            );
        } else if (_principal == 0) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidLoanParameter.selector,
                    _PRINCIPAL_ERROR_ID_
                )
            );
        } else if (
            _duration == 0 ||
            (block.timestamp + uint256(_duration) + uint256(_gracePeriod)) >
            type(uint32).max
        ) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidLoanParameter.selector,
                    _DURATION_ERROR_ID_
                )
            );
        }
    }

    function verifyLatestDebtId(
        address _loanContractAddress,
        address _collateralAddress,
        uint256 _debtId
    ) public {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);

        // Verify debt ID for collateral
        uint256 numDebtIds = _loanContract.getCollateralNonce(
            _collateralAddress,
            collateralId
        );

        assertEq(
            _loanContract.debtIds(
                _collateralAddress,
                collateralId,
                numDebtIds - 1
            ),
            _debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        _loanContract.debtIds(_collateralAddress, collateralId, numDebtIds);
    }

    function verifyLoanAgreementTerms(
        address _borrower,
        address _loanContractAddress,
        uint256 _debtId,
        TestTermsStruct memory _termsStruct
    ) public {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);

        // Verify loan agreement terms for this debt ID
        assertEq(
            _loanContract.loanState(_debtId),
            _termsStruct.loanState,
            "Invalid loan state"
        );
        assertEq(
            _loanContract.firInterval(_debtId),
            _termsStruct.firInterval,
            "Invalid fir interval"
        );
        assertEq(
            _loanContract.fixedInterestRate(_debtId),
            _termsStruct.fixedInterestRate,
            "Invalid fixed interest rate"
        );
        assertEq(
            _loanContract.loanClose(_debtId) - _loanContract.loanStart(_debtId),
            _termsStruct.duration,
            "Invalid duration"
        );
        assertEq(
            _loanContract.borrower(_debtId),
            _borrower,
            "Invalid borrower"
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

    function verifyTokenBalances(
        address _borrower,
        address _lender,
        address _anzaTokenAddress,
        uint256 _debtId,
        uint128 _principal
    ) public {
        // Verify token balances
        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(_debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(_debtId);

        address[] memory accounts = new address[](2);
        accounts[0] = _lender;
        accounts[1] = _borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = uint256(_principal);
        balances[1] = 1;

        assertEq(
            IERC1155(_anzaTokenAddress).balanceOfBatch(accounts, ids),
            balances
        );
    }
}

contract LoanContractTestSubmit is LoanContractSubmitFunctions, LoanSigned {
    uint256 thing = 0x10;

    function setUp() public virtual override {
        super.setUp();
    }

    function testBasicLenderSubmitProposal() public {
        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _PRINCIPAL_,
            _DURATION_,
            _GRACE_PERIOD_,
            _TERMS_EXPIRY_
        );

        // Submit proposal
        vm.deal(lender, _PRINCIPAL_);
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

        if (_PRINCIPAL_ == 0 || _DURATION_ == 0 || _TERMS_EXPIRY_ == 0) {
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
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: _ACTIVE_GRACE_STATE_,
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: 0,
                gracePeriod: 0,
                duration: _DURATION_,
                termsExpiry: 0
            })
        );

        // Verify loan participants
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_);

        // Verify token balances
        verifyTokenBalances(
            borrower,
            lender,
            address(anzaToken),
            _debtId,
            _PRINCIPAL_
        );

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }
}

contract LoanContractFuzzSubmit is
    ILoanContractEvents,
    LoanContractDeployer,
    LoanContractSubmitFunctions
{
    uint256 collateralNonce = 0;

    function setUp() public virtual override {
        super.setUp();
    }

    function testAnyFixedInterestRateLenderSubmitProposal(
        uint8 _fixedInterestRate
    ) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1f, _FIR_INTERVAL_)
            mstore(0x1e, _fixedInterestRate)
            mstore(0x1b, _PRINCIPAL_)
            mstore(0x0b, _GRACE_PERIOD_)
            mstore(0x07, _DURATION_)
            mstore(0x03, _TERMS_EXPIRY_)

            _contractTerms := mload(0x20)
        }

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        bytes memory _signature = abi.encodePacked(r, s, v);

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        // Submit proposal
        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _PRINCIPAL_,
            _DURATION_,
            _GRACE_PERIOD_,
            _TERMS_EXPIRY_
        );

        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                collateralId,
                _signature
            )
        );
        require(success);
        vm.stopPrank();

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
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: _ACTIVE_GRACE_STATE_,
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _fixedInterestRate,
                principal: 0,
                gracePeriod: 0,
                duration: _DURATION_,
                termsExpiry: 0
            })
        );

        // Verify loan participants
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_);

        // Verify token balances
        verifyTokenBalances(
            borrower,
            lender,
            address(anzaToken),
            _debtId,
            _PRINCIPAL_
        );

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }

    function testAnyPrincipalLenderSubmitProposal(uint128 _principal) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1f, _FIR_INTERVAL_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1b, _principal)
            mstore(0x0b, _GRACE_PERIOD_)
            mstore(0x07, _DURATION_)
            mstore(0x03, _TERMS_EXPIRY_)

            _contractTerms := mload(0x20)
        }

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        bytes memory _signature = abi.encodePacked(r, s, v);

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _principal,
            _DURATION_,
            _GRACE_PERIOD_,
            _TERMS_EXPIRY_
        );

        // Submit proposal
        vm.deal(lender, uint256(_principal) + 1 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: _principal}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                collateralId,
                _signature
            )
        );
        require(success);
        vm.stopPrank();

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
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: _ACTIVE_GRACE_STATE_,
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: 0,
                gracePeriod: 0,
                duration: _DURATION_,
                termsExpiry: 0
            })
        );

        // Verify loan participants
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _principal);

        // Verify token balances
        verifyTokenBalances(
            borrower,
            lender,
            address(anzaToken),
            _debtId,
            _principal
        );

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }

    function testAnyGracePeriodLenderSubmitProposal(
        uint32 _gracePeriod
    ) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1f, _FIR_INTERVAL_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1b, _PRINCIPAL_)
            mstore(0x0b, _gracePeriod)
            mstore(0x07, _DURATION_)
            mstore(0x03, _TERMS_EXPIRY_)

            _contractTerms := mload(0x20)
        }

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        bytes memory _signature = abi.encodePacked(r, s, v);

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _PRINCIPAL_,
            _DURATION_,
            _gracePeriod,
            _TERMS_EXPIRY_
        );

        // Submit proposal
        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                collateralId,
                _signature
            )
        );
        require(success);
        vm.stopPrank();

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
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: _ACTIVE_GRACE_STATE_,
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: 0,
                gracePeriod: 0,
                duration: _DURATION_,
                termsExpiry: 0
            })
        );

        // Verify loan participants
        verifyLoanParticipants(address(anzaToken), lender, _debtId);

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_);

        // Verify token balances
        verifyTokenBalances(
            borrower,
            lender,
            address(anzaToken),
            _debtId,
            _PRINCIPAL_
        );

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }

    function testAnyDurationLenderSubmitProposal(uint32 _duration) public {
        vm.assume(block.timestamp + uint256(_duration) < type(uint32).max);

        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1f, _FIR_INTERVAL_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1b, _PRINCIPAL_)
            mstore(0x0b, _GRACE_PERIOD_)
            mstore(0x07, _duration)
            mstore(0x03, _TERMS_EXPIRY_)

            _contractTerms := mload(0x20)
        }

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        bytes memory _signature = abi.encodePacked(r, s, v);

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _PRINCIPAL_,
            _duration,
            _GRACE_PERIOD_,
            _TERMS_EXPIRY_
        );

        // Submit proposal
        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                collateralId,
                _signature
            )
        );
        require(success);
        vm.stopPrank();

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
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: _ACTIVE_GRACE_STATE_,
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: 0,
                gracePeriod: 0,
                duration: _duration,
                termsExpiry: 0
            })
        );

        // Verify loan participants
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_);

        // Verify token balances
        verifyTokenBalances(
            borrower,
            lender,
            address(anzaToken),
            _debtId,
            _PRINCIPAL_
        );

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }

    function testAnyTermsExpiryLenderSubmitProposal(
        uint32 _termsExpiry
    ) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1f, _FIR_INTERVAL_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1b, _PRINCIPAL_)
            mstore(0x0b, _GRACE_PERIOD_)
            mstore(0x07, _DURATION_)
            mstore(0x03, _termsExpiry)

            _contractTerms := mload(0x20)
        }

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        bytes memory _signature = abi.encodePacked(r, s, v);

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _PRINCIPAL_,
            _DURATION_,
            _GRACE_PERIOD_,
            _termsExpiry
        );

        // Submit proposal
        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: _PRINCIPAL_}(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                collateralId,
                _signature
            )
        );
        require(success);
        vm.stopPrank();

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
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: _ACTIVE_GRACE_STATE_,
                firInterval: _FIR_INTERVAL_,
                fixedInterestRate: _FIXED_INTEREST_RATE_,
                principal: 0,
                gracePeriod: 0,
                duration: _DURATION_,
                termsExpiry: 0
            })
        );

        // Verify loan participants
        uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        assertEq(
            anzaToken.ownerOf(_lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(_debtId), _PRINCIPAL_);

        // Verify token balances
        verifyTokenBalances(
            borrower,
            lender,
            address(anzaToken),
            _debtId,
            _PRINCIPAL_
        );

        // Minted lender NFT should have debt token URI
        assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // Verify debtId is updated at end
        _debtId = loanContract.totalDebts();
        assertEq(_debtId, 1);
    }

    function testAllLenderSubmitProposal(
        TestTermsStruct memory _termsStruct
    ) public {
        _termsStruct.firInterval = bound(
            _termsStruct.firInterval,
            0,
            (2 ** 4) - 1
        );

        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1f, mload(add(_termsStruct, 0x20)))
            mstore(0x1e, mload(add(_termsStruct, 0x40)))
            mstore(0x1b, mload(add(_termsStruct, 0x60)))
            mstore(0x0b, mload(add(_termsStruct, 0x80)))
            mstore(0x07, mload(add(_termsStruct, 0xa0)))
            mstore(0x03, mload(add(_termsStruct, 0xc0)))

            _contractTerms := mload(0x20)
        }

        // Create message for signing
        bytes32 message = Signing.prefixed(
            keccak256(
                abi.encode(
                    _contractTerms,
                    address(demoToken),
                    collateralId,
                    collateralNonce
                )
            )
        );

        // Sign borrower's terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, message);
        bytes memory _signature = abi.encodePacked(r, s, v);

        uint256 _debtId = loanContract.totalDebts();
        assertEq(_debtId, 0);

        initLoanContractExpectations(
            address(loanContract),
            lender,
            address(demoToken),
            _debtId,
            _termsStruct.principal,
            _termsStruct.duration,
            _termsStruct.gracePeriod,
            _termsStruct.termsExpiry
        );

        // Submit proposal
        vm.deal(lender, uint256(_termsStruct.principal) + 1 ether);
        vm.startPrank(lender);
        (bool success, ) = address(loanContract).call{
            value: _termsStruct.principal
        }(
            abi.encodeWithSignature(
                "initLoanContract(bytes32,address,uint256,bytes)",
                _contractTerms,
                address(demoToken),
                collateralId,
                _signature
            )
        );
        require(success);
        vm.stopPrank();

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
        vm.deal(borrower, 100 ether);
        vm.startPrank(borrower);
        loanContract.mintReplica(_debtId);
        vm.stopPrank();

        // Verify debt ID for collateral
        verifyLatestDebtId(address(loanContract), address(demoToken), _debtId);

        // Verify loan agreement terms for this debt ID
        verifyLoanAgreementTerms(
            borrower,
            address(loanContract),
            _debtId,
            TestTermsStruct({
                loanState: _ACTIVE_GRACE_STATE_,
                firInterval: _termsStruct.firInterval,
                fixedInterestRate: _termsStruct.fixedInterestRate,
                principal: 0,
                gracePeriod: 0,
                duration: _termsStruct.duration,
                termsExpiry: 0
            })
        );

        // // Verify loan participants
        // uint256 _lenderTokenId = Indexer.getLenderTokenId(_debtId);
        // assertEq(
        //     anzaToken.ownerOf(_lenderTokenId),
        //     lender,
        //     "Invalid lender token ID"
        // );

        // // Verify total debt balance
        // assertEq(loanContract.debtBalanceOf(_debtId), _termsStruct.principal);

        // // Verify token balances
        // verifyTokenBalances(
        //     borrower,
        //     lender,
        //     address(anzaToken),
        //     _debtId,
        //     _termsStruct.principal
        // );

        // // Minted lender NFT should have debt token URI
        // assertEq(anzaToken.uri(_lenderTokenId), getTokenURI(_lenderTokenId));

        // // Verify debtId is updated at end
        // _debtId = loanContract.totalDebts();
        // assertEq(_debtId, 1);
    }
}
