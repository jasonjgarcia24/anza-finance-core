// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import {IAnzaERC721Events} from "./interfaces/IAnzaERC721Events.t.sol";
import {ILoanContractEvents} from "./interfaces/ILoanContractEvents.t.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LoanContractGlobalConstants, LoanContractDeployer, LoanSigned, LoanContractMinter} from "./LoanContract.t.sol";
import {LoanContractTestERC1155URIStorage} from "./LoanContractDeployment.t.sol";
import {DemoToken} from "../contracts/DemoToken.sol";
import {LibLoanContractStates as States} from "../contracts/utils/LibLoanContractStates.sol";
import {LibLoanContractMetadata as Metadata, LibLoanContractSigning as Signing, LibLoanContractIndexer as Indexer} from "../contracts/libraries/LibLoanContract.sol";

contract LoanContractTestSubmit is
    LoanContractGlobalConstants,
    LoanSigned,
    ILoanContractEvents,
    IAnzaERC721Events
{
    uint256 thing = 0x10;

    function setUp() public virtual override {
        super.setUp();
    }

    function testBasicLenderSubmitProposal() public {
        uint256 debtId = loanContract.totalDebts();
        assertEq(debtId, 0);

        // Anza batch NFT minting
        vm.expectEmit(true, true, true, true);
        emit TransferAnzaBatch(
            lender,
            address(0),
            [lender, borrower],
            [(debtId * 2), (debtId * 2) + 1],
            [uint256(_PRINCIPAL_), uint256(1)]
        );

        // Loan proposal submitted
        vm.expectEmit(true, true, true, true);
        emit LoanContractInitialized(address(demoToken), collateralId, debtId);

        // Submit proposal
        vm.deal(lender, 100 ether);
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

        // Verify debt ID for collateral
        uint256 numDebtIds = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        assertEq(
            loanContract.debtIds(
                address(demoToken),
                collateralId,
                numDebtIds - 1
            ),
            debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        loanContract.debtIds(address(demoToken), collateralId, numDebtIds);

        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(debtId),
            _ACTIVE_GRACE_STATE_,
            "Invalid loan state"
        );
        assertEq(
            loanContract.fixedInterestRate(debtId),
            _FIXED_INTEREST_RATE_,
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.principal(debtId),
            _PRINCIPAL_,
            "Invalid principal"
        );
        assertEq(
            loanContract.loanClose(debtId) - loanContract.loanStart(debtId),
            _DURATION_,
            "Invalid duration"
        );

        // Verify loan participants
        assertEq(loanContract.borrowerOf(debtId), borrower, "Invalid borrower");
        assertEq(loanContract.lenderOf(debtId), lender, "Invalid lender");

        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(debtId);

        assertEq(
            loanContract.ownerOf(borrowerTokenId),
            borrower,
            "Invalid borrower token ID"
        );
        assertEq(
            loanContract.ownerOf(lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(borrower, debtId), _PRINCIPAL_);

        // Verify token balances
        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _PRINCIPAL_;
        balances[1] = 1;

        assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(debtId), _getTokenURI(debtId));

        // Verify debtId is updated at end
        debtId = loanContract.totalDebts();
        assertEq(debtId, 1);
    }

    function _getTokenURI(
        uint256 _tokenId
    ) internal view returns (string memory) {
        return string(abi.encodePacked(nftsURI, Strings.toString(_tokenId)));
    }
}

contract LoanContractFuzzSubmit is
    LoanContractGlobalConstants,
    LoanContractDeployer,
    ILoanContractEvents,
    IAnzaERC721Events
{
    uint256 collateralNonce = 0;
    bytes32 contractTerms;

    bytes public signature;

    struct TestTermsStruct {
        uint8 fixedInterestRate;
        uint128 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
    }

    function setUp() public virtual override {
        super.setUp();
    }

    function testAnyFixedInterestRateLenderSubmitProposal(
        uint8 _fixedInterestRate
    ) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1e, _fixedInterestRate)
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

        uint256 debtId = loanContract.totalDebts();

        // Anza batch NFT minting
        vm.expectEmit(true, true, true, true);
        emit TransferAnzaBatch(
            lender,
            address(0),
            [lender, borrower],
            [(debtId * 2), (debtId * 2) + 1],
            [uint256(_PRINCIPAL_), 1]
        );

        // Loan proposal submitted
        vm.expectEmit(true, true, true, true);
        emit LoanContractInitialized(address(demoToken), collateralId, debtId);

        // Submit proposal
        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
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

        // Verify debt ID for collateral
        uint256 numDebtIds = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        assertEq(
            loanContract.debtIds(
                address(demoToken),
                collateralId,
                numDebtIds - 1
            ),
            debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        loanContract.debtIds(address(demoToken), collateralId, numDebtIds);

        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(debtId),
            _ACTIVE_GRACE_STATE_,
            "Invalid loan state"
        );
        assertEq(
            loanContract.fixedInterestRate(debtId),
            _fixedInterestRate,
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.principal(debtId),
            _PRINCIPAL_,
            "Invalid principal"
        );
        assertEq(
            loanContract.loanClose(debtId) - loanContract.loanStart(debtId),
            _DURATION_,
            "Invalid duration"
        );

        // Verify loan participants
        assertEq(loanContract.borrowerOf(debtId), borrower, "Invalid borrower");
        assertEq(loanContract.lenderOf(debtId), lender, "Invalid lender");

        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(debtId);

        assertEq(
            loanContract.ownerOf(borrowerTokenId),
            borrower,
            "Invalid borrower token ID"
        );
        assertEq(
            loanContract.ownerOf(lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(borrower, debtId), _PRINCIPAL_);

        // Verify token balances
        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _PRINCIPAL_;
        balances[1] = 1;

        assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(debtId), _getTokenURI(debtId));

        // Verify debtId is updated at end
        debtId = loanContract.totalDebts();
        assertEq(debtId, 1);
    }

    function testAnyPrincipalLenderSubmitProposal(uint128 _principal) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1c, _principal)
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

        uint256 debtId = loanContract.totalDebts();

        // Anza batch NFT minting
        vm.expectEmit(true, true, true, true);
        emit TransferAnzaBatch(
            lender,
            address(0),
            [lender, borrower],
            [(debtId * 2), (debtId * 2) + 1],
            [uint256(_principal), 1]
        );

        // Loan proposal submitted
        vm.expectEmit(true, true, true, true);
        emit LoanContractInitialized(address(demoToken), collateralId, debtId);

        // Submit proposal
        vm.deal(lender, uint256(_principal) + 1 ether);
        vm.startPrank(lender);

        (bool success, ) = address(loanContract).call{value: _principal}(
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

        // Verify debt ID for collateral
        uint256 numDebtIds = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        assertEq(
            loanContract.debtIds(
                address(demoToken),
                collateralId,
                numDebtIds - 1
            ),
            debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        loanContract.debtIds(address(demoToken), collateralId, numDebtIds);

        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(debtId),
            _ACTIVE_GRACE_STATE_,
            "Invalid loan state"
        );
        assertEq(
            loanContract.fixedInterestRate(debtId),
            _FIXED_INTEREST_RATE_,
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.principal(debtId),
            _principal,
            "Invalid principal"
        );
        assertEq(
            loanContract.loanClose(debtId) - loanContract.loanStart(debtId),
            _DURATION_,
            "Invalid duration"
        );

        // Verify loan participants
        assertEq(loanContract.borrowerOf(debtId), borrower, "Invalid borrower");
        assertEq(loanContract.lenderOf(debtId), lender, "Invalid lender");

        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(debtId);

        assertEq(
            loanContract.ownerOf(borrowerTokenId),
            borrower,
            "Invalid borrower token ID"
        );
        assertEq(
            loanContract.ownerOf(lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(borrower, debtId), _principal);

        // Verify token balances
        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _principal;
        balances[1] = 1;

        assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(debtId), _getTokenURI(debtId));

        // Verify debtId is updated at end
        debtId = loanContract.totalDebts();
        assertEq(debtId, 1);
    }

    function testAnyGracePeriodLenderSubmitProposal(
        uint32 _gracePeriod
    ) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1c, _PRINCIPAL_)
            mstore(0x0c, _gracePeriod)
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

        uint256 debtId = loanContract.totalDebts();

        // Anza batch NFT minting
        vm.expectEmit(true, true, true, true);
        emit TransferAnzaBatch(
            lender,
            address(0),
            [lender, borrower],
            [(debtId * 2), (debtId * 2) + 1],
            [uint256(_PRINCIPAL_), 1]
        );

        // Loan proposal submitted
        vm.expectEmit(true, true, true, true);
        emit LoanContractInitialized(address(demoToken), collateralId, debtId);

        // Submit proposal
        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
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

        // Verify debt ID for collateral
        uint256 numDebtIds = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        assertEq(
            loanContract.debtIds(
                address(demoToken),
                collateralId,
                numDebtIds - 1
            ),
            debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        loanContract.debtIds(address(demoToken), collateralId, numDebtIds);

        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(debtId),
            _ACTIVE_GRACE_STATE_,
            "Invalid loan state"
        );
        assertEq(
            loanContract.fixedInterestRate(debtId),
            _FIXED_INTEREST_RATE_,
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.principal(debtId),
            _PRINCIPAL_,
            "Invalid principal"
        );
        assertEq(
            loanContract.loanClose(debtId) - loanContract.loanStart(debtId),
            _DURATION_,
            "Invalid duration"
        );

        // Verify loan participants
        assertEq(loanContract.borrowerOf(debtId), borrower, "Invalid borrower");
        assertEq(loanContract.lenderOf(debtId), lender, "Invalid lender");

        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(debtId);

        assertEq(
            loanContract.ownerOf(borrowerTokenId),
            borrower,
            "Invalid borrower token ID"
        );
        assertEq(
            loanContract.ownerOf(lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(borrower, debtId), _PRINCIPAL_);

        // Verify token balances
        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _PRINCIPAL_;
        balances[1] = 1;

        assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(debtId), _getTokenURI(debtId));

        // Verify debtId is updated at end
        debtId = loanContract.totalDebts();
        assertEq(debtId, 1);
    }

    function testAnyDurationLenderSubmitProposal(uint32 _duration) public {
        vm.assume(block.timestamp + uint256(_duration) < type(uint32).max);

        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1c, _PRINCIPAL_)
            mstore(0x0c, _GRACE_PERIOD_)
            mstore(0x08, _duration)
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

        uint256 debtId = loanContract.totalDebts();

        // Anza batch NFT minting
        vm.expectEmit(true, true, true, true);
        emit TransferAnzaBatch(
            lender,
            address(0),
            [lender, borrower],
            [(debtId * 2), (debtId * 2) + 1],
            [uint256(_PRINCIPAL_), 1]
        );

        // Loan proposal submitted
        vm.expectEmit(true, true, true, true);
        emit LoanContractInitialized(address(demoToken), collateralId, debtId);

        // Submit proposal
        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
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

        // Verify debt ID for collateral
        uint256 numDebtIds = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        console.log(_duration);

        assertEq(
            loanContract.debtIds(
                address(demoToken),
                collateralId,
                numDebtIds - 1
            ),
            debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        loanContract.debtIds(address(demoToken), collateralId, numDebtIds);

        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(debtId),
            _ACTIVE_GRACE_STATE_,
            "Invalid loan state"
        );
        assertEq(
            loanContract.fixedInterestRate(debtId),
            _FIXED_INTEREST_RATE_,
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.principal(debtId),
            _PRINCIPAL_,
            "Invalid principal"
        );

        assertEq(
            loanContract.loanClose(debtId) - loanContract.loanStart(debtId),
            uint256(_duration),
            "Invalid duration"
        );

        // Verify loan participants
        assertEq(loanContract.borrowerOf(debtId), borrower, "Invalid borrower");
        assertEq(loanContract.lenderOf(debtId), lender, "Invalid lender");

        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(debtId);

        assertEq(
            loanContract.ownerOf(borrowerTokenId),
            borrower,
            "Invalid borrower token ID"
        );
        assertEq(
            loanContract.ownerOf(lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(borrower, debtId), _PRINCIPAL_);

        // Verify token balances
        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _PRINCIPAL_;
        balances[1] = 1;

        assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(debtId), _getTokenURI(debtId));

        // Verify debtId is updated at end
        debtId = loanContract.totalDebts();
        assertEq(debtId, 1);
    }

    function testAnyTermsExpiryLenderSubmitProposal(
        uint32 _termsExpiry
    ) public {
        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1e, _FIXED_INTEREST_RATE_)
            mstore(0x1c, _PRINCIPAL_)
            mstore(0x0c, _GRACE_PERIOD_)
            mstore(0x08, _DURATION_)
            mstore(0x04, _termsExpiry)

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

        uint256 debtId = loanContract.totalDebts();

        // Anza batch NFT minting
        vm.expectEmit(true, true, true, true);
        emit TransferAnzaBatch(
            lender,
            address(0),
            [lender, borrower],
            [(debtId * 2), (debtId * 2) + 1],
            [uint256(_PRINCIPAL_), 1]
        );

        // Loan proposal submitted
        vm.expectEmit(true, true, true, true);
        emit LoanContractInitialized(address(demoToken), collateralId, debtId);

        // Submit proposal
        vm.deal(lender, uint256(_PRINCIPAL_) + 1 ether);
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

        // Verify debt ID for collateral
        uint256 numDebtIds = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        assertEq(
            loanContract.debtIds(
                address(demoToken),
                collateralId,
                numDebtIds - 1
            ),
            debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        loanContract.debtIds(address(demoToken), collateralId, numDebtIds);

        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(debtId),
            _ACTIVE_GRACE_STATE_,
            "Invalid loan state"
        );
        assertEq(
            loanContract.fixedInterestRate(debtId),
            _FIXED_INTEREST_RATE_,
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.principal(debtId),
            _PRINCIPAL_,
            "Invalid principal"
        );

        assertEq(
            loanContract.loanClose(debtId) - loanContract.loanStart(debtId),
            _DURATION_,
            "Invalid duration"
        );

        // Verify loan participants
        assertEq(loanContract.borrowerOf(debtId), borrower, "Invalid borrower");
        assertEq(loanContract.lenderOf(debtId), lender, "Invalid lender");

        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(debtId);

        assertEq(
            loanContract.ownerOf(borrowerTokenId),
            borrower,
            "Invalid borrower token ID"
        );
        assertEq(
            loanContract.ownerOf(lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(loanContract.debtBalanceOf(borrower, debtId), _PRINCIPAL_);

        // Verify token balances
        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _PRINCIPAL_;
        balances[1] = 1;

        assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(debtId), _getTokenURI(debtId));

        // Verify debtId is updated at end
        debtId = loanContract.totalDebts();
        assertEq(debtId, 1);
    }

    function testAnyAllLenderSubmitProposal(
        TestTermsStruct memory _termsStruct
    ) public {
        vm.assume(
            block.timestamp + uint256(_termsStruct.duration) < type(uint32).max
        );
        // vm.assume(_termsStruct.principal != 0);
        // vm.assume(_termsStruct.duration != 0);
        // vm.assume(_termsStruct.termsExpiry != 0);

        bytes32 _contractTerms;

        assembly {
            mstore(0x20, _LOAN_STATE_)
            mstore(0x1e, mload(_termsStruct))
            mstore(0x1c, mload(add(_termsStruct, 0x20)))
            mstore(0x0c, mload(add(_termsStruct, 0x40)))
            mstore(0x08, mload(add(_termsStruct, 0x60)))
            mstore(0x04, mload(add(_termsStruct, 0x80)))

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
        bytes memory signature = abi.encodePacked(r, s, v);

        uint256 debtId = loanContract.totalDebts();

        // Anza batch NFT minting
        vm.expectEmit(true, true, true, true);
        emit TransferAnzaBatch(
            lender,
            address(0),
            [lender, borrower],
            [(debtId * 2), (debtId * 2) + 1],
            [uint256(_termsStruct.principal), 1]
        );

        // Loan proposal submitted
        vm.expectEmit(true, true, true, true);
        emit LoanContractInitialized(address(demoToken), collateralId, debtId);

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
                signature
            )
        );
        require(success);
        vm.stopPrank();

        // Verify debt ID for collateral
        uint256 numDebtIds = loanContract.getCollateralNonce(
            address(demoToken),
            collateralId
        );

        assertEq(
            loanContract.debtIds(
                address(demoToken),
                collateralId,
                numDebtIds - 1
            ),
            debtId
        );

        // Verify no additional debtIds set for this collateral
        vm.expectRevert(bytes(""));
        loanContract.debtIds(address(demoToken), collateralId, numDebtIds);

        // Verify loan agreement terms for this debt ID
        assertEq(
            loanContract.loanState(debtId),
            _ACTIVE_GRACE_STATE_,
            "Invalid loan state"
        );
        assertEq(
            loanContract.fixedInterestRate(debtId),
            uint256(_termsStruct.fixedInterestRate),
            "Invalid fixed interest rate"
        );
        assertEq(
            loanContract.principal(debtId),
            uint256(_termsStruct.principal),
            "Invalid principal"
        );
        assertEq(
            loanContract.loanClose(debtId) - loanContract.loanStart(debtId),
            uint256(_termsStruct.duration),
            "Invalid duration"
        );

        // Verify loan participants
        assertEq(loanContract.borrowerOf(debtId), borrower, "Invalid borrower");
        assertEq(loanContract.lenderOf(debtId), lender, "Invalid lender");

        uint256 borrowerTokenId = Indexer.getBorrowerTokenId(debtId);
        uint256 lenderTokenId = Indexer.getLenderTokenId(debtId);

        assertEq(
            loanContract.ownerOf(borrowerTokenId),
            borrower,
            "Invalid borrower token ID"
        );
        assertEq(
            loanContract.ownerOf(lenderTokenId),
            lender,
            "Invalid lender token ID"
        );

        // Verify total debt balance
        assertEq(
            loanContract.debtBalanceOf(borrower, debtId),
            _termsStruct.principal
        );

        // Verify token balances
        address[] memory accounts = new address[](2);
        accounts[0] = lender;
        accounts[1] = borrower;

        uint256[] memory ids = new uint256[](2);
        ids[0] = lenderTokenId;
        ids[1] = borrowerTokenId;

        uint256[] memory balances = new uint256[](2);
        balances[0] = _termsStruct.principal;
        balances[1] = 1;

        assertEq(loanContract.balanceOfBatch(accounts, ids), balances);

        // Minted borrower NFT should have nftURI
        assertEq(loanContract.uri(debtId), _getTokenURI(debtId));

        // Verify debtId is updated at end
        debtId = loanContract.totalDebts();
        assertEq(debtId, 1);
    }

    function _getTokenURI(
        uint256 _tokenId
    ) internal view returns (string memory) {
        return string(abi.encodePacked(nftsURI, Strings.toString(_tokenId)));
    }
}
