// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import "@custom-errors/StdVaultErrors.sol";
import {_INVALID_COLLATERAL_SELECTOR_} from "@custom-errors/StdLoanErrors.sol";

import {LoanTreasurey} from "@base/services/LoanTreasurey.sol";
import {CollateralVault} from "@services/CollateralVault.sol";
import {ICollateralVault} from "@services-interfaces/ICollateralVault.sol";
import {AnzaTokenIndexer} from "@tokens-libraries/AnzaTokenIndexer.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {DebtBookHarness} from "@test-databases/DebtBook__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";
import {ICollateralVaultEvents, CollateralVaultEventsSuite} from "@test-utils/events/CollateralVaultEventsSuite__test.sol";
import {IERC721Events} from "@test-utils/events/ERC721EventsSuite__test.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CollateralVaultHarness is CollateralVault {
    struct RecordInput {
        address from;
        address collateralAddress;
        uint256 collateralId;
        uint256 debtId;
        uint256 activeLoanIndex;
    }

    constructor(address _anzaToken) CollateralVault(_anzaToken) {}

    function exposed__record(
        address _from,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) public {
        _record(
            _from,
            _collateralAddress,
            _collateralId,
            _debtId,
            _activeLoanIndex
        );
    }
}

abstract contract CollateralVaultInit is Setup {
    DebtBookHarness public debtBookHarness;
    AnzaTokenHarness public anzaTokenHarness;
    CollateralVaultHarness public collateralVaultHarness;

    DemoToken internal _demoToken;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy DebtBook
        debtBookHarness = new DebtBookHarness();

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();
        anzaTokenHarness.grantRole(_TREASURER_, address(loanTreasurer));

        // Deploy LoanTreasurey
        loanTreasurer = new LoanTreasurey();

        // Deploy CollateralVault
        collateralVaultHarness = new CollateralVaultHarness(
            address(anzaTokenHarness)
        );

        // Set AnzaToken access control roles
        anzaTokenHarness.grantRole(
            _COLLATERAL_VAULT_,
            address(collateralVaultHarness)
        );
        anzaTokenHarness.grantRole(_TREASURER_, address(loanTreasurer));

        // Set CollateralVault access control roles
        collateralVaultHarness.setLoanContract(address(debtBookHarness));
        collateralVaultHarness.grantRole(_TREASURER_, address(loanTreasurer));

        // Set harnessed DebtBook access control roles
        debtBookHarness.exposed__setAnzaToken(address(anzaTokenHarness));
        debtBookHarness.exposed__setCollateralVault(
            address(collateralVaultHarness)
        );

        vm.stopPrank();

        // Deploy DemoToken with no token balance.
        _demoToken = new DemoToken(0);
    }
}

contract CollateralVaultUnitTest is
    CollateralVaultInit,
    IERC721Events,
    ICollateralVaultEvents,
    CollateralVaultEventsSuite
{
    using AnzaTokenIndexer for uint256;

    function setUp() public virtual override {
        super.setUp();
    }

    /**
     * Test the internal record function.
     *
     * @notice This test also tests the getCollateral() function.
     *
     * @param _borrower The borrower address.
     * @param _collateralId The collateral ID.
     * @param _debtId The debt ID.
     * @param _activeLoanIndex The active loan index.
     *
     * @dev Full pass if the function initial reverts as expected and then
     * passes with an updated debt ID.
     */
    function _testCollateralVault__Record(
        address _borrower,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        function(address, address, uint256, uint256, uint256) external recorder
    ) internal {
        vm.assume(_borrower != address(0));

        // Fail expected due to debt ID misalignment.
        vm.expectRevert(_UNALLOWED_DEPOSIT_);
        recorder(
            _borrower,
            address(_demoToken),
            _collateralId,
            _debtId,
            _activeLoanIndex
        );

        _debtId = bound(_debtId, 1, type(uint256).max);

        // Mint collateral and approve loan contract.
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Update totalDebts within DebtBook.
        debtBookHarness.exposed__setTotalDebts(_debtId - 1);

        // Write debt to DebtBook.
        debtBookHarness.exposed__writeDebt(address(_demoToken), _collateralId);

        // Record collateral.
        recorder(
            _borrower,
            address(_demoToken),
            _collateralId,
            _debtId,
            _activeLoanIndex
        );

        ICollateralVault.Collateral memory collateral = collateralVaultHarness
            .getCollateral(_debtId);

        assertEq(
            collateral.collateralAddress,
            address(_demoToken),
            "0 :: collateral address mismatch."
        );
        assertEq(
            collateral.collateralId,
            _collateralId,
            "1 :: collateral id mismatch."
        );
        assertEq(
            collateral.activeLoanIndex,
            _activeLoanIndex,
            "2 :: active loan index mismatch."
        );
    }

    function _simulateDeposit(
        address _borrower,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        uint256 _amount,
        function(address, uint256) external returns (uint256, uint256) writeDebt
    ) internal {
        writeDebt(_collateralAddress, _collateralId);
        collateralVaultHarness.exposed__record(
            _borrower,
            _collateralAddress,
            _collateralId,
            _debtId,
            _activeLoanIndex
        );
        anzaTokenHarness.exposed__mint(
            _borrower,
            _debtId.debtIdToBorrowerTokenId(),
            _debtId
        );
        anzaTokenHarness.exposed__mint(
            lender,
            _debtId.debtIdToLenderTokenId(),
            _amount
        );
    }

    /* --------------- CollateralVault._record() --------------- */
    /**
     * See {testCollateralVault__Record()} for testing.
     */
    function testCollateralVault__Record(
        address _borrower,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) public {
        _testCollateralVault__Record(
            _borrower,
            _collateralId,
            _debtId,
            _activeLoanIndex,
            collateralVaultHarness.exposed__record
        );
    }

    /* ------------ CollateralVault.getCollateral() ------------ */
    /**
     * See {testCollateralVault__Record()} for testing.
     */

    /* ------------ CollateralVault.setCollateral() ------------ */
    /**
     * Test the set collateral function.
     */
    function testCollateralVault_SetCollateral(
        address _borrower,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) public {
        vm.startPrank(address(debtBookHarness));
        _testCollateralVault__Record(
            _borrower,
            _collateralId,
            _debtId,
            _activeLoanIndex,
            collateralVaultHarness.setCollateral
        );
    }

    /* ---------- CollateralVault.withdrawAllowed() ---------- */
    /**
     * Test the withdraw allowed function.
     *
     * @param _borrower The borrower address.
     * @param _altAccount The alternate account address that should not
     * be allowed to withdraw.
     * @param _collateralId The collateral ID.
     * @param _activeLoanIndex The active loan index.
     * @param _principals The principal amounts.
     *
     * @dev Full pass if the function reverts are as expected.
     * @dev Full pass if the function only returns true when the debt
     * balance is zero and the `_to` is the borrower.
     */
    function testCollateralVault_WithdrawAllowed_Fuzz(
        address _borrower,
        address _altAccount,
        uint256 _collateralId,
        uint256 _activeLoanIndex,
        uint128[20] memory _principals
    ) public {
        vm.assume(_borrower != address(0) && _borrower.code.length == 0);
        vm.assume(_altAccount != _borrower);

        for (uint256 i = 0; i < _principals.length; i++) {
            vm.assume(_principals[i] > 0);
        }

        uint256 _debtId = _principals.length;

        // Fail expected due to debt ID misalignment with DebtBook
        // records.
        vm.expectRevert(_UNALLOWED_DEPOSIT_);
        collateralVaultHarness.exposed__record(
            _borrower,
            address(_demoToken),
            _collateralId,
            _debtId,
            _activeLoanIndex
        );

        // Mint collateral and approve loan contract.
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Write debt to DebtBook and corresponding AnzaTokens.
        _simulateDeposit(
            _borrower,
            address(_demoToken),
            _collateralId,
            1,
            0,
            _principals[0],
            debtBookHarness.exposed__writeDebt
        );

        assertEq(
            collateralVaultHarness.totalCollateral(),
            1,
            "0 :: total collateral mismatch."
        );

        for (uint256 i = 1; i < _debtId; ++i) {
            _simulateDeposit(
                _borrower,
                address(_demoToken),
                _collateralId,
                i + 1,
                i,
                _principals[i],
                debtBookHarness.exposed__appendDebt
            );
        }

        // FALSE :: Check withdraw allowed.
        vm.expectRevert(_INVALID_COLLATERAL_SELECTOR_);
        collateralVaultHarness.withdrawAllowed(_borrower, type(uint256).max);

        assertFalse(
            collateralVaultHarness.withdrawAllowed(_borrower, _debtId),
            "0 :: withdraw allowed mismatch."
        );

        assertFalse(
            collateralVaultHarness.withdrawAllowed(_altAccount, _debtId),
            "1 :: withdraw allowed mismatch."
        );

        // TRUE :: Check withdraw allowed.
        vm.startPrank(address(loanTreasurer));

        for (uint256 i = 0; i < _debtId - 1; ++i) {
            anzaTokenHarness.burnLenderToken(i + 1, _principals[i]);

            assertFalse(
                collateralVaultHarness.withdrawAllowed(_borrower, _debtId),
                "2 :: withdraw allowed mismatch."
            );

            assertFalse(
                collateralVaultHarness.withdrawAllowed(_altAccount, _debtId),
                "3 :: withdraw allowed mismatch."
            );
        }

        anzaTokenHarness.burnLenderToken(_debtId, _principals[_debtId - 1]);

        assertTrue(
            collateralVaultHarness.withdrawAllowed(_borrower, _debtId),
            "4 :: withdraw allowed mismatch."
        );

        assertFalse(
            collateralVaultHarness.withdrawAllowed(_altAccount, _debtId),
            "5 :: withdraw allowed mismatch."
        );

        vm.stopPrank();
    }

    /* -------------- CollateralVault.withdraw() ------------- */
    /**
     * Test the withdraw function.
     *
     * @param _borrower The borrower address.
     * @param _altAccount The alternate account address that should not
     * be allowed to withdraw.
     * @param _collateralId The collateral ID.
     * @param _principal The principal amount.
     *
     * @dev Full pass if the function reverts are as expected.
     * @dev Full pass if the function only allows a withdrawal when the debt
     * balance is zero and the `_to` is the borrower.
     */
    function testCollateralVault_Withdraw_Fuzz(
        address _borrower,
        address _altAccount,
        uint256 _collateralId,
        uint128 _principal
    ) public {
        vm.assume(_borrower != address(0) && _borrower.code.length == 0);
        vm.assume(_altAccount != _borrower);
        vm.assume(_principal > 0);

        uint256 _debtId = 1;

        // Fail expected due to access control.
        vm.expectRevert(
            abi.encodePacked(
                getAccessControlFailMsg(_TREASURER_, address(this))
            )
        );
        collateralVaultHarness.withdraw(_borrower, _debtId);

        // Fail expected due to invalid collateral.
        vm.expectRevert(_INVALID_COLLATERAL_SELECTOR_);
        vm.startPrank(address(loanTreasurer));
        collateralVaultHarness.withdraw(_borrower, _debtId);
        vm.stopPrank();

        // Mint collateral and approve loan contract.
        _demoToken.exposed__mint(_borrower, _collateralId);

        // Write debt to DebtBook and corresponding AnzaTokens.
        debtBookHarness.exposed__writeDebt(address(_demoToken), _collateralId);

        vm.startPrank(_borrower);
        _demoToken.approve(address(debtBookHarness), _collateralId);
        vm.stopPrank();

        vm.startPrank(address(debtBookHarness));
        _demoToken.safeTransferFrom(
            _borrower,
            address(collateralVaultHarness),
            _collateralId,
            abi.encodePacked(_debtId)
        );
        vm.stopPrank();

        assertEq(
            collateralVaultHarness.totalCollateral(),
            1,
            "0 :: total collateral mismatch."
        );

        anzaTokenHarness.exposed__mint(
            _borrower,
            _debtId.debtIdToBorrowerTokenId(),
            _debtId
        );
        anzaTokenHarness.exposed__mint(
            lender,
            _debtId.debtIdToLenderTokenId(),
            _principal
        );

        // Fail expected due to withdraw not allowed.
        vm.startPrank(address(loanTreasurer));

        vm.expectRevert(_UNALLOWED_WITHDRAWAL_);
        collateralVaultHarness.withdraw(_borrower, _debtId);

        anzaTokenHarness.burnLenderToken(_debtId, _principal);

        // Fail expected due to withdraw not allowed for non-borrower account.
        vm.expectRevert(_UNALLOWED_WITHDRAWAL_);
        collateralVaultHarness.withdraw(_altAccount, _debtId);

        // Successful withdraw expected.
        vm.expectEmit(true, true, true, false, address(_demoToken));
        emit Transfer(
            address(collateralVaultHarness),
            _borrower,
            _collateralId
        );
        vm.expectEmit(true, true, true, false, address(collateralVaultHarness));
        emit WithdrawnCollateral(_borrower, address(_demoToken), _collateralId);
        assertTrue(
            collateralVaultHarness.withdraw(_borrower, _debtId),
            "1 :: withdraw failed."
        );

        assertEq(
            collateralVaultHarness.totalCollateral(),
            0,
            "2 :: total collateral mismatch."
        );

        vm.stopPrank();
    }

    /* ---------- CollateralVault.onERC721Received() --------- */
    /**
     * Test the onERC721Received function.
     *
     * @param _altOperator The alternate operator address that should not
     * be allowed to deposit.
     * @param _altBorrower The alternate borrower address that will allow
     * to be included in the DepositCollateral event.
     * @param _collateralId The collateral ID.
     *
     * @dev Full pass if the function reverts are as expected.
     * @dev Full pass if the function only allows deposits with the correct
     * parameters.
     */
    function testCollateralVault_OnERC721Received_Fuzz(
        address _altOperator,
        address _altBorrower,
        uint256 _collateralId
    ) public {
        vm.assume(_altOperator != address(_demoToken));
        vm.assume(_altBorrower != borrower);

        uint256 _debtId = 1;

        // Mint collateral and approve loan contract.
        _demoToken.exposed__mint(borrower, _collateralId);

        // Fail due to invalid caller.
        vm.expectRevert(_UNALLOWED_DEPOSIT_);
        collateralVaultHarness.onERC721Received(
            address(debtBookHarness),
            borrower,
            _collateralId,
            abi.encodePacked(_debtId)
        );

        // Write debt to DebtBook and corresponding AnzaTokens.
        debtBookHarness.exposed__writeDebt(address(_demoToken), _collateralId);

        vm.startPrank(address(_demoToken));

        // Fail due to invalid operator.
        vm.expectRevert(
            abi.encodePacked(
                getAccessControlFailMsg(_LOAN_CONTRACT_, _altOperator)
            )
        );
        collateralVaultHarness.onERC721Received(
            _altOperator,
            borrower,
            _collateralId,
            abi.encodePacked(_debtId)
        );

        // Will pass if the borrower is not the actual borrower.
        // The borrower for this function must be verified prior to calling this function.
        // Given the onERC721Received function can only be derived from a LoanContract call,
        // this should be safe.
        // collateralVaultHarness.onERC721Received(
        //     address(debtBookHarness),
        //     _altBorrower,
        //     _collateralId,
        //     abi.encodePacked(_debtId)
        // );

        // Fail due to invalid collateral ID.
        vm.expectRevert(_UNALLOWED_DEPOSIT_);
        unchecked {
            // Allow overflow.
            collateralVaultHarness.onERC721Received(
                address(debtBookHarness),
                borrower,
                _collateralId + 1,
                abi.encodePacked(_debtId)
            );
        }

        // Fail due to invalid debt ID.
        vm.expectRevert(_UNALLOWED_DEPOSIT_);
        collateralVaultHarness.onERC721Received(
            address(debtBookHarness),
            borrower,
            _collateralId,
            abi.encodePacked(_debtId + 1)
        );

        // Successful deposit expected.
        vm.expectEmit(true, true, true, false, address(collateralVaultHarness));
        emit DepositedCollateral(borrower, address(_demoToken), _collateralId);
        collateralVaultHarness.onERC721Received(
            address(debtBookHarness),
            borrower,
            _collateralId,
            abi.encodePacked(_debtId)
        );
        vm.stopPrank();
    }
}
