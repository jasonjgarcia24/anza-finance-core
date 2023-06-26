// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_PRINCIPAL_, _MAX_DEBT_ID_, _MAX_REFINANCES_} from "@lending-constants/LoanContractNumbers.sol";
import {_INVALID_COLLATERAL_SELECTOR_} from "@custom-errors/StdLoanErrors.sol";
import {_ILLEGAL_MINT_SELECTOR_, _INVALID_TOKEN_ID_SELECTOR_} from "@custom-errors/StdAnzaTokenErrors.sol";

import {DebtBook} from "@lending-databases/DebtBook.sol";
import {AnzaToken} from "@tokens/AnzaToken.sol";
import {LoanTreasurey} from "@services/LoanTreasurey.sol";
import {CollateralVault} from "@services/CollateralVault.sol";
import {AnzaDebtStorefront} from "@storefronts/AnzaDebtStorefront.sol";
import {AnzaSponsorshipStorefront} from "@storefronts/AnzaSponsorshipStorefront.sol";
import {AnzaRefinanceStorefront} from "@storefronts/AnzaRefinanceStorefront.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";
import {CollateralVaultHarness} from "@test-base/_CollateralVault/CollateralVault__test.sol";
import {StringUtils} from "@test-utils/test-utils/StringUtils.sol";

contract DebtBookHarness is DebtBook {
    constructor() DebtBook() {}

    function exposed__setAnzaToken(address _anzaTokenAddress) public {
        _setAnzaToken(_anzaTokenAddress);
    }

    function exposed__setCollateralVault(
        address _collateralVaultAddress
    ) public {
        _setCollateralVault(_collateralVaultAddress);
    }

    function exposed__writeDebt(
        address _collateralAddres,
        uint256 _collateralId
    ) public returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        return _writeDebt(_collateralAddres, _collateralId);
    }

    function exposed__appendDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) public returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        return _appendDebt(_collateralAddress, _collateralId);
    }

    /* Abstract functions */
    function setAnzaToken(address _anzaTokenAddress) public virtual override {}

    function setCollateralVault(
        address _collateralVaultAddress
    ) public virtual override {}
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract DebtBookInit is Setup {
    DebtBookHarness public debtBookHarness;
    AnzaTokenHarness public anzaTokenHarness;
    CollateralVaultHarness public collateralVaultHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy DebtBook
        debtBookHarness = new DebtBookHarness();

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();

        // Deploy CollateralVault
        collateralVaultHarness = new CollateralVaultHarness(
            address(anzaTokenHarness)
        );

        // Set AnzaToken access control roles
        anzaTokenHarness.grantRole(_LOAN_CONTRACT_, address(loanContract));
        anzaTokenHarness.grantRole(_TREASURER_, address(loanTreasurer));
        anzaTokenHarness.grantRole(
            _COLLATERAL_VAULT_,
            address(collateralVaultHarness)
        );

        // Set LoanContract access control roles
        loanContract.setAnzaToken(address(anzaTokenHarness));
        loanContract.setCollateralVault(address(collateralVaultHarness));

        // Set LoanTreasurey access control roles
        loanTreasurer.setAnzaToken(address(anzaTokenHarness));
        loanTreasurer.setCollateralVault(address(collateralVaultHarness));

        // Set CollateralVault access control roles
        collateralVaultHarness.setLoanContract(address(debtBookHarness));
        collateralVaultHarness.grantRole(_TREASURER_, address(loanTreasurer));

        anzaDebtStorefront = new AnzaDebtStorefront(
            address(anzaTokenHarness),
            address(loanContract),
            address(loanTreasurer)
        );

        anzaSponsorshipStorefront = new AnzaSponsorshipStorefront(
            address(anzaTokenHarness),
            address(loanContract),
            address(loanTreasurer)
        );

        anzaRefinanceStorefront = new AnzaRefinanceStorefront(
            address(anzaTokenHarness),
            address(loanContract),
            address(loanTreasurer)
        );

        // Set harnessed DebtBook access control roles
        debtBookHarness.exposed__setAnzaToken(address(anzaTokenHarness));
        debtBookHarness.exposed__setCollateralVault(
            address(collateralVaultHarness)
        );

        vm.stopPrank();
    }
}

contract DebtBookAccessControlTest is DebtBookInit {
    function setUp() public virtual override {
        super.setUp();
    }

    function testDebtBook__SetAnzaToken() public {
        debtBookHarness.exposed__setAnzaToken(address(anzaToken));
        assertEq(debtBookHarness.anzaToken(), address(anzaToken));

        AnzaToken _newAnzaToken = new AnzaToken("www.anza.io");
        debtBookHarness.exposed__setAnzaToken(address(_newAnzaToken));
        assertEq(debtBookHarness.anzaToken(), address(_newAnzaToken));
    }

    function testDebtBook__FuzzGetAnzaTokenFail(address _anzaToken) public {
        vm.assume(_anzaToken != address(anzaToken));
        assertTrue(debtBookHarness.anzaToken() != _anzaToken);
    }

    function testDebtBook__SetCollateralVault() public {
        debtBookHarness.exposed__setCollateralVault(address(collateralVault));
        assertEq(debtBookHarness.collateralVault(), address(collateralVault));

        AnzaToken _newAnzaToken = new AnzaToken("www.anza.io");
        CollateralVault _newCollateralVault = new CollateralVault(
            address(_newAnzaToken)
        );
        debtBookHarness.exposed__setCollateralVault(
            address(_newCollateralVault)
        );
        assertEq(
            debtBookHarness.collateralVault(),
            address(_newCollateralVault)
        );
    }

    function testDebtBook__FuzzGetCollateralVaultFail(
        address _collateralVault
    ) public {
        vm.assume(_collateralVault != address(collateralVault));
        assertTrue(debtBookHarness.collateralVault() != _collateralVault);
    }
}

contract DebtBookUnitTest is DebtBookInit {
    struct FuzzCollateralInput {
        address collateralAddress;
        uint256 collateralId;
        uint256[] amounts;
    }

    struct FuzzCollateralStorage {
        uint256[] debtIds;
        uint256[] collateralNonces;
        uint256 debtBalance;
        uint256 debtCount;
    }

    mapping(address collateralAddress => mapping(uint256 collateralId => FuzzCollateralStorage))
        public collateralData;

    function setUp() public virtual override {
        super.setUp();
    }

    /* ----------- DebtBook.debtBalance() ----------- */
    /**
     * Fuzz test the debt balance for a random token ID and debt amount.
     *
     * @param _amount The amount of debt to mint.
     * @param _tokenId The token ID to mint debt for (not debt ID).
     *
     * @dev Full pass if the token ID is for a lender's token and the debt
     * balance is equal to the minted amount, or full pass if the token ID
     * is for a borrower's token and the debt balance is equal to 0.
     * @dev Caught fail/pass if the minted amount is 0 and the function reverts
     * with the expected erro message.
     */
    function testDebtBook__FuzzTokenId_DebtBalance(
        uint256 _amount,
        uint256 _tokenId
    ) public {
        uint256 _debtId = anzaTokenHarness.debtId(_tokenId);

        try anzaTokenHarness.exposed__mint(lender, _tokenId, _amount) {
            assertEq(
                loanContract.debtBalance(_debtId),
                _tokenId % 2 == 0 ? _amount : 0,
                "0 :: debt balance does not equal expected lender balance."
            );
        } catch (bytes memory _err) {
            if (_amount == 0) {
                assertTrue(
                    bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                    "0 :: 'illegal mint selector failure' expected."
                );
            } else {
                unexpectedFail(
                    "not 'illegal mint selector failure', should not fail",
                    _err
                );
            }
        }
    }

    /**
     * Fuzz test the debt balance for a random debt ID.
     *
     * @param _debtId The debt ID to mint debt for.
     *
     * TODO: Add test to check non-zero debt balance.
     *
     * @dev Full pass if the debt balance is equal to 0.
     * @dev Caught fail/pass if the minted amount is 0 and the function reverts
     * with the expected erro message.
     */
    function testDebtBook__FuzzDebtId_DebtBalance(uint256 _debtId) public {
        try loanContract.debtBalance(_debtId) returns (uint256 _debtBalance) {
            assertEq(
                _debtBalance,
                0,
                "0 :: debt balance does not equal expected lender balance."
            );
        } catch (bytes memory _err) {
            if (_debtId > _MAX_DEBT_ID_) {
                assertTrue(
                    bytes4(_err) == _INVALID_TOKEN_ID_SELECTOR_,
                    "0 :: 'invalid token id selector failure' expected."
                );
            } else {
                unexpectedFail(
                    "not 'invalid token id selector failure', should not fail",
                    _err
                );
            }
        }
    }

    /* ----------- DebtBook.borrowerDebtBalance() ----------- */
    /**
     * Fuzz test the lender debt balance function with random token ID.
     *
     * @dev Full pass if the token ID is for a lender's token.
     * @dev Caught fail/pass if the token ID is for a borrower's token and
     * the function reverts with the expected error message.
     * @dev Caught fail/pass if the amount is 0 and the function reverts with
     * the expected error message.
     */
    function testDebtBook__FuzzTokenId_LenderDebtBalance(
        uint256 _amount,
        uint256 _tokenId
    ) public {
        uint256 _debtId = anzaTokenHarness.debtId(_tokenId);

        try anzaTokenHarness.exposed__mint(lender, _tokenId, _amount) {
            try loanContract.lenderDebtBalance(_debtId) returns (
                uint256 _lenderDebtBalance
            ) {
                assertEq(
                    _lenderDebtBalance,
                    _amount,
                    "0 :: debt balance does not equal expected lender balance."
                );
            } catch Error(string memory _err) {
                // The token ID was for a borrower's token, failure is expected.
                if (_tokenId % 2 == 1) {
                    assertEq(
                        _err,
                        "ERC1155: address zero is not a valid owner",
                        "0 :: ERC1155 address zero failure expected."
                    );
                }
                // The token ID was for a lender's token, failure is unexpected.
                else {
                    unexpectedFail(
                        "not 'address zero...' failure, should not fail",
                        _err
                    );
                }
            }
        } catch (bytes memory _err) {
            if (_amount == 0) {
                assertTrue(
                    bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                    "0 :: 'illegal mint selector failure' expected."
                );
            } else {
                unexpectedFail(
                    "not 'illegal mint selector failure', should not fail",
                    _err
                );
            }
        }
    }

    /* ----------- DebtBook.borrowerDebtBalance() ----------- */
    /**
     * Fuzz test the borrower debt balance function with a random token ID.
     *
     * @dev Full pass if the token ID is for a borrower's token.
     * @dev Caught fail/pass if the token ID is for a lender's token and the
     * function reverts with the expected error message.
     * @dev Caught fail/pass if the amount is 0 and the function reverts with
     * the expected error message.
     */
    function testDebtBook__FuzzTokenId_BorrowerDebtBalance(
        uint256 _amount,
        uint256 _tokenId
    ) public {
        uint256 _debtId = anzaTokenHarness.debtId(_tokenId);

        try anzaTokenHarness.exposed__mint(borrower, _tokenId, _amount) {
            try loanContract.borrowerDebtBalance(_debtId) returns (
                uint256 _borrowerDebtBalance
            ) {
                assertEq(
                    _borrowerDebtBalance,
                    _amount,
                    "0 :: debt balance does not equal expected borrower balance."
                );
            } catch Error(string memory _err) {
                // The token ID was for a lender's token, failure is expected.
                if (_tokenId % 2 == 0) {
                    assertEq(
                        _err,
                        "ERC1155: address zero is not a valid owner",
                        "0 :: ERC1155 address zero failure expected."
                    );
                }
                // The token ID was for a borrower's token, failure is unexpected.
                else {
                    unexpectedFail(
                        "not 'address zero...' failure, should not fail",
                        _err
                    );
                }
            }
        } catch (bytes memory _err) {
            if (_amount == 0) {
                assertTrue(
                    bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                    "0 :: 'illegal mint selector failure' expected."
                );
            } else {
                unexpectedFail(
                    "not 'illegal mint selector failure', should not fail",
                    _err
                );
            }
        }
    }

    /* ----------- DebtBook.collateralDebtBalance() ----------- */
    /**
     * Fuzz test the collateral debt balance function with random debt
     * balances.
     *
     * @notice This test removes zero amount debt mints from the test set.
     *
     * @dev Full pass if the debt balance is the expected value.
     * @dev No test if the sum of the fuzzed amount is 0.
     */
    function testDebtBook__Fuzz_CollateralDebtBalance(
        FuzzCollateralInput[] memory _collaterals
    ) public {
        uint256 _maxCollateralLoops = 10;
        uint256 _maxAmountLoops = 10;

        // Limit number of collateral loops for time.
        uint256 _collateralLoops = _collaterals.length > _maxCollateralLoops
            ? _maxCollateralLoops
            : _collaterals.length;
        vm.assume(_collateralLoops > 0);

        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];

            // Limit number of amount loops for time.
            uint256 _amountLoops = _collateral.amounts.length > _maxAmountLoops
                ? _maxAmountLoops
                : _collateral.amounts.length;

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            if (_collateral.collateralAddress != address(0)) {
                for (uint256 i; i < _amountLoops; ++i) {
                    uint256 _lenderTokenId = anzaTokenHarness.lenderTokenId(
                        ++_collateralData.debtCount
                    );
                    _collateral.amounts[i] = bound(
                        _collateral.amounts[i],
                        0,
                        _MAX_DEBT_PRINCIPAL_
                    );

                    try
                        anzaTokenHarness.exposed__mint(
                            lender,
                            _lenderTokenId,
                            _collateral.amounts[i]
                        )
                    {
                        // Write/append debt to debt book if successful mint.
                        _collateralData.debtCount == 0
                            ? debtBookHarness.exposed__writeDebt(
                                _collateral.collateralAddress,
                                _collateral.collateralId
                            )
                            : debtBookHarness.exposed__appendDebt(
                                _collateral.collateralAddress,
                                _collateral.collateralId
                            );

                        // Accumulate debt balance for later validation.
                        _collateralData.debtBalance += _collateral.amounts[i];
                        _collateralData.debtIds.push(
                            debtBookHarness.totalDebts()
                        );
                        _collateralData.collateralNonces.push(
                            _collateralData.debtCount
                        );
                    } catch (bytes memory _err) {
                        // If fail, revert debt count to previous value.
                        --_collateralData.debtCount;

                        if (_collateral.amounts[i] == 0) {
                            assertTrue(
                                bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                                "0 :: 'illegal mint selector failure' expected."
                            );
                        } else {
                            unexpectedFail(
                                "not 'illegal mint selector failure', should not fail",
                                _err
                            );
                        }
                    }
                }
            }

            // Only perform comparison if there was a debt balance.
            if (_collateralData.debtCount > 0) {
                try
                    debtBookHarness.collateralDebtBalance(
                        _collateral.collateralAddress,
                        _collateral.collateralId
                    )
                returns (uint256 _debtBalance) {
                    assertEq(
                        _debtBalance,
                        _collateralData.debtBalance,
                        "1 :: collateral debt balance does not equal expected value."
                    );
                } catch (bytes memory _err) {
                    if (_collateral.collateralAddress == address(0)) {
                        assertTrue(
                            bytes4(_err) == _INVALID_COLLATERAL_SELECTOR_,
                            "0 :: 'invalid collateral selector failure' expected."
                        );
                    }
                }
            }
        }
    }

    /* ----------- DebtBook.collateralDebtCount() ----------- */
    /**
     * Fuzz test the collateral debt count function with random collateral
     * and debt counts.
     *
     * @dev Full pass if the debt count is the expected value.
     */
    function testDebtBook__Fuzz_CollateralDebtCount(
        address _collateralAddress,
        uint256 _collateralId,
        uint8 _debtCount
    ) public {
        if (_debtCount > 0) {
            debtBookHarness.exposed__writeDebt(
                _collateralAddress,
                _collateralId
            );

            for (uint256 i; i < _debtCount - 1; ++i) {
                debtBookHarness.exposed__appendDebt(
                    _collateralAddress,
                    _collateralId
                );
            }
        }

        assertEq(
            debtBookHarness.collateralDebtCount(
                _collateralAddress,
                _collateralId
            ),
            _debtCount,
            "0 :: collateral debt count does not equal expected value."
        );
    }

    /* ----------- DebtBook.collateralDebtAt() ----------- */
    /**
     * Fuzz test the collateral debt at function with random debt balances.
     *
     * @notice Test Function:
     *  collateralDebtAt(address,uint256,uint256)
     *      public
     *      view
     *      returns (uint256, uint256);
     *
     * @param _amounts The debt balances.
     *
     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the index calls.
     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the type(uint256).max index call.
     * @dev Caught fail/pass if the amount is 0 and the function reverts with
     * the expected error message.
     * @dev Caught fail/pass if the debt count is 0 and the function reverts with
     * the expected error message.
     */
    function testDebtBook__FuzzAmounts_CollateralDebtAt(
        uint256[] memory _amounts
    ) public {
        uint256 _debtBalance;
        uint256 _debtCount;
        uint256[] memory _debtIds = new uint256[](_amounts.length);
        uint256[] memory _collateralNonces = new uint256[](_amounts.length);

        for (uint256 i; i < _amounts.length; ++i) {
            uint256 _lenderTokenId = anzaTokenHarness.lenderTokenId(
                ++_debtCount
            );
            _amounts[i] = bound(_amounts[i], 0, _MAX_DEBT_PRINCIPAL_);

            try
                anzaTokenHarness.exposed__mint(
                    lender,
                    _lenderTokenId,
                    _amounts[i]
                )
            {
                // Write/append debt to debt book if successful mint.
                _debtBalance == 0
                    ? debtBookHarness.exposed__writeDebt(
                        address(anzaTokenHarness),
                        collateralId
                    )
                    : debtBookHarness.exposed__appendDebt(
                        address(anzaTokenHarness),
                        collateralId
                    );

                // Accumulate debt balance for later validation.
                _debtBalance += _amounts[i];
                _debtIds[_debtCount - 1] = debtBookHarness.totalDebts();
                _collateralNonces[_debtCount - 1] = _debtCount;
            } catch (bytes memory _err) {
                // If fail, revert debt count to previous value.
                --_debtCount;

                if (_amounts[i] == 0) {
                    assertTrue(
                        bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                        "0 :: 'illegal mint selector failure' expected."
                    );
                } else {
                    unexpectedFail(
                        "not 'illegal mint selector failure', should not fail",
                        _err
                    );
                }
            }
        }

        // Test collateral debt at calls with indexes.
        for (uint256 i; i < _amounts.length; ++i) {
            try
                debtBookHarness.collateralDebtAt(
                    address(anzaTokenHarness),
                    collateralId,
                    i
                )
            returns (uint256 _debtId, uint256 _collateralNonce) {
                assertEq(
                    _debtId,
                    _debtIds[i],
                    "1 :: debt ID does not equal expected value."
                );

                assertEq(
                    _collateralNonce,
                    _collateralNonces[i],
                    "2 :: collateral nonce does not equal expected value."
                );
            } catch (bytes memory _err) {
                if (_debtCount == 0 || i >= _debtCount) {
                    assertEq(
                        _err,
                        stdError.indexOOBError,
                        "3 :: 'index out of bounds' expected."
                    );
                } else {
                    unexpectedFail(
                        "not 'index out of bounds', should not fail",
                        _err
                    );
                }
            }
        }

        // Test collateral debt at calls with max uint256.
        // Should return last collateral debt.
        try
            debtBookHarness.collateralDebtAt(
                address(anzaTokenHarness),
                collateralId,
                type(uint256).max
            )
        returns (uint256 _debtId, uint256 _collateralNonce) {
            assertEq(
                _debtId,
                _debtIds[_debtCount - 1],
                "4 :: debt ID does not equal expected value."
            );

            assertEq(
                _collateralNonce,
                _collateralNonces[_debtCount - 1],
                "5 :: collateral nonce does not equal expected value."
            );
        } catch (bytes memory _err) {
            if (_debtCount == 0) {
                assertEq(
                    _err,
                    stdError.arithmeticError,
                    "6 :: 'arithmetic over/underflow' expected."
                );
            } else {
                unexpectedFail(
                    "not 'arithmetic over/underflow'', should not fail",
                    _err
                );
            }
        }
    }

    /**
     * Fuzz test the collateral debt at function with random collaterals.
     *
     * @notice Test Function:
     *  collateralDebtAt(address,uint256,uint256)
     *      public
     *      view
     *      returns (uint256, uint256);
     *
     * @param _collaterals FuzzCollateralInput struct with collateralAddress,
     * collateralId, and amounts (i.e. debt balances). Note: Only the 
     * collateralAddress and collateralId are used in this test.

     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the index calls.
     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the type(uint256).max index call.
     * @dev Caught fail/pass if the amount is 0 and the function reverts with
     * the expected error message.
     * @dev Caught fail/pass if the debt count is 0 and the function reverts with
     * the expected error message.
     */
    function testDebtBook__FuzzCollateral_CollateralDebtAt(
        FuzzCollateralInput[] memory _collaterals
    ) public {
        uint256 _maxCollateralLoops = 10;
        uint256[10] memory _amounts = [
            uint256(1),
            uint256(2),
            uint256(3),
            uint256(4),
            uint256(5),
            uint256(10),
            uint256(100),
            uint256(1000),
            uint256(333),
            uint256(21)
        ];

        // Limit number of collateral loops for time.
        uint256 _collateralLoops = _collaterals.length > _maxCollateralLoops
            ? _maxCollateralLoops
            : _collaterals.length;
        vm.assume(_collateralLoops > 0);

        for (uint256 j; j < _collateralLoops; ++j) {
            // Limit number of amount loops for time.
            FuzzCollateralInput memory _collateral = _collaterals[j];
            vm.assume(_collateral.collateralAddress != address(0));

            for (uint256 i; i < _amounts.length; ++i) {
                FuzzCollateralStorage storage _collateralData = collateralData[
                    _collateral.collateralAddress
                ][_collateral.collateralId];

                uint256 _lenderTokenId = anzaTokenHarness.lenderTokenId(
                    ++_collateralData.debtCount
                );
                _amounts[i] = bound(_amounts[i], 0, _MAX_DEBT_PRINCIPAL_);

                try
                    anzaTokenHarness.exposed__mint(
                        lender,
                        _lenderTokenId,
                        _amounts[i]
                    )
                {
                    // Write/append debt to debt book if successful mint.
                    _collateralData.debtBalance == 0
                        ? debtBookHarness.exposed__writeDebt(
                            _collateral.collateralAddress,
                            _collateral.collateralId
                        )
                        : debtBookHarness.exposed__appendDebt(
                            _collateral.collateralAddress,
                            _collateral.collateralId
                        );

                    // Accumulate debt balance for later validation.
                    _collateralData.debtBalance += _amounts[i];
                    _collateralData.debtIds.push(debtBookHarness.totalDebts());
                    _collateralData.collateralNonces.push(
                        _collateralData.debtCount
                    );
                } catch (bytes memory _err) {
                    // If fail, revert debt count to previous value.
                    --_collateralData.debtCount;

                    if (_amounts[i] == 0) {
                        assertTrue(
                            bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                            "0 :: 'illegal mint selector failure' expected."
                        );
                    } else {
                        unexpectedFail(
                            "not 'illegal mint selector failure', should not fail",
                            _err
                        );
                    }
                }
            }
        }

        // Test collateral debt at calls with indexes.
        for (uint256 j; j < _collateralLoops; ++j) {
            // Limit number of amount loops for time.
            FuzzCollateralInput memory _collateral = _collaterals[j];

            for (uint256 i; i < _amounts.length; ++i) {
                FuzzCollateralStorage storage _collateralData = collateralData[
                    _collateral.collateralAddress
                ][_collateral.collateralId];

                try
                    debtBookHarness.collateralDebtAt(
                        _collateral.collateralAddress,
                        _collateral.collateralId,
                        i
                    )
                returns (uint256 _debtId, uint256 _collateralNonce) {
                    assertEq(
                        _debtId,
                        _collateralData.debtIds[i],
                        "1 :: debt ID does not equal expected value."
                    );

                    assertEq(
                        _collateralNonce,
                        _collateralData.collateralNonces[i],
                        "2 :: collateral nonce does not equal expected value."
                    );
                } catch (bytes memory _err) {
                    if (
                        _collateral.collateralAddress == address(0) ||
                        _collateralData.debtCount == 0 ||
                        i >= _collateralData.debtCount
                    ) {
                        assertEq(
                            _err,
                            stdError.indexOOBError,
                            "3 :: 'index out of bounds' expected."
                        );
                    } else {
                        unexpectedFail(
                            "not 'index out of bounds', should not fail",
                            _err
                        );
                    }
                }
            }
        }

        // Test collateral debt at calls with max uint256.
        // Should return last collateral debt.
        for (uint256 j; j < _collateralLoops; ++j) {
            // Limit number of amount loops for time.
            FuzzCollateralInput memory _collateral = _collaterals[j];

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            try
                debtBookHarness.collateralDebtAt(
                    _collateral.collateralAddress,
                    _collateral.collateralId,
                    type(uint256).max
                )
            returns (uint256 _debtId, uint256 _collateralNonce) {
                assertEq(
                    _debtId,
                    _collateralData.debtIds[_collateralData.debtCount - 1],
                    "4 :: debt ID does not equal expected value."
                );

                assertEq(
                    _collateralNonce,
                    _collateralData.collateralNonces[
                        _collateralData.debtCount - 1
                    ],
                    "5 :: collateral nonce does not equal expected value."
                );
            } catch (bytes memory _err) {
                if (_collateralData.debtCount == 0) {} else {
                    unexpectedFail(
                        "not 'arithmetic over/underflow'', should not fail",
                        _err
                    );

                    emit log("Error: should not fail.");
                    emit log_named_bytes("Unexpected error", _err);
                    assertTrue(false);
                }
            }
        }
    }

    /**
     * Fuzz test the collateral debt at function with random debt balances and
     * collaterals.
     *
     * @notice Test Function:
     *  collateralDebtAt(address,uint256,uint256)
     *      public
     *      view
     *      returns (uint256, uint256);
     *
     * @param _collaterals FuzzCollateralInput struct with collateralAddress,
     * collateralId, and amounts (i.e. debt balances).
     *
     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the index calls.
     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the type(uint256).max index call.
     * @dev Caught fail/pass if the amount is 0 and the function reverts with
     * the expected error message.
     * @dev Caught fail/pass if the debt count is 0 and the function reverts with
     * the expected error message.
     */
    function testDebtBook__Fuzz_CollateralDebtAt(
        FuzzCollateralInput[] memory _collaterals
    ) public {
        uint256 _maxCollateralLoops = 10;
        uint256 _maxAmountLoops = 10;

        // Limit number of collateral loops for time.
        uint256 _collateralLoops = _collaterals.length > _maxCollateralLoops
            ? _maxCollateralLoops
            : _collaterals.length;
        vm.assume(_collateralLoops > 0);

        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];
            vm.assume(_collateral.collateralAddress != address(0));

            // Limit number of amount loops for time.
            uint256 _amountLoops = _collateral.amounts.length > _maxAmountLoops
                ? _maxAmountLoops
                : _collateral.amounts.length;

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            for (uint256 i; i < _amountLoops; ++i) {
                uint256 _lenderTokenId = anzaTokenHarness.lenderTokenId(
                    ++_collateralData.debtCount
                );
                _collateral.amounts[i] = bound(
                    _collateral.amounts[i],
                    0,
                    _MAX_DEBT_PRINCIPAL_
                );

                try
                    anzaTokenHarness.exposed__mint(
                        lender,
                        _lenderTokenId,
                        _collateral.amounts[i]
                    )
                {
                    // Write/append debt to debt book if successful mint.
                    _collateralData.debtBalance == 0
                        ? debtBookHarness.exposed__writeDebt(
                            _collateral.collateralAddress,
                            _collateral.collateralId
                        )
                        : debtBookHarness.exposed__appendDebt(
                            _collateral.collateralAddress,
                            _collateral.collateralId
                        );

                    // Accumulate debt balance for later validation.
                    _collateralData.debtBalance += _collateral.amounts[i];
                    _collateralData.debtIds.push(debtBookHarness.totalDebts());
                    _collateralData.collateralNonces.push(
                        _collateralData.debtCount
                    );
                } catch (bytes memory _err) {
                    // If fail, revert debt count to previous value.
                    --_collateralData.debtCount;

                    if (_collateral.amounts[i] == 0) {
                        assertTrue(
                            bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                            "0 :: 'illegal mint selector failure' expected."
                        );
                    } else {
                        unexpectedFail(
                            "not 'illegal mint selector failure', should not fail",
                            _err
                        );
                    }
                }
            }
        }

        // Test collateral debt at calls with indexes.
        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];

            // Limit number of amount loops for time.
            uint256 _amountLoops = _collateral.amounts.length > _maxAmountLoops
                ? _maxAmountLoops
                : _collateral.amounts.length;

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            for (uint256 i; i < _amountLoops; ++i) {
                try
                    debtBookHarness.collateralDebtAt(
                        _collateral.collateralAddress,
                        _collateral.collateralId,
                        i
                    )
                returns (uint256 _debtId, uint256 _collateralNonce) {
                    assertEq(
                        _debtId,
                        _collateralData.debtIds[i],
                        "1 :: debt ID does not equal expected value."
                    );

                    assertEq(
                        _collateralNonce,
                        _collateralData.collateralNonces[i],
                        "2 :: collateral nonce does not equal expected value."
                    );
                } catch (bytes memory _err) {
                    if (
                        _collateral.collateralAddress == address(0) ||
                        _collateralData.debtCount == 0 ||
                        i >= _collateralData.debtCount
                    ) {
                        assertEq(
                            _err,
                            stdError.indexOOBError,
                            "3 :: 'index out of bounds' expected."
                        );
                    } else {
                        unexpectedFail(
                            "not 'index out of bounds', should not fail",
                            _err
                        );
                    }
                }
            }
        }

        // Test collateral debt at calls with max uint256.
        // Should return last collateral debt.
        for (uint256 j; j < _collateralLoops; ++j) {
            // Limit number of amount loops for time.
            FuzzCollateralInput memory _collateral = _collaterals[j];

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            try
                debtBookHarness.collateralDebtAt(
                    _collateral.collateralAddress,
                    _collateral.collateralId,
                    type(uint256).max
                )
            returns (uint256 _debtId, uint256 _collateralNonce) {
                assertEq(
                    _debtId,
                    _collateralData.debtIds[_collateralData.debtCount - 1],
                    "4 :: debt ID does not equal expected value."
                );

                assertEq(
                    _collateralNonce,
                    _collateralData.collateralNonces[
                        _collateralData.debtCount - 1
                    ],
                    "5 :: collateral nonce does not equal expected value."
                );
            } catch (bytes memory _err) {
                if (_collateralData.debtCount == 0) {
                    assertEq(
                        _err,
                        stdError.arithmeticError,
                        "6 :: 'arithmetic over/underflow' expected."
                    );
                } else {
                    unexpectedFail(
                        "not 'arithmetic over/underflow', should not fail",
                        _err
                    );
                }
            }
        }
    }

    /**
     * Fuzz test the collateral debt at function with random debt balances.
     *
     * @notice Test Function:
     *  collateralDebtAt(uint256, uint256)
     *      public
     *      view
     *      returns (uint256, uint256);
     *
     * @param _amounts The debt balances.
     *
     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the index calls.
     * @dev Full pass if the debt balance and collateral nonce are the expected
     * values at the type(uint256).max index call.
     * @dev Caught fail/pass if the amount is 0 and the function reverts with
     * the expected error message.
     * @dev Caught fail/pass if the debt count is 0 and the function reverts with
     * the expected error message.
     */
    function testDebtBook__FuzzDebtId_CollateralDebtAt(
        uint256[] memory _amounts
    ) public {
        vm.assume(_amounts.length > 0);

        uint256 _debtBalance;
        uint256 _debtCount;
        uint256[] memory _debtIds = new uint256[](_amounts.length);
        uint256[] memory _collateralNonces = new uint256[](_amounts.length);

        // Store debt
        for (uint256 i; i < _amounts.length; ++i) {
            uint256 _lenderTokenId = anzaTokenHarness.lenderTokenId(
                ++_debtCount
            );
            _amounts[i] = bound(_amounts[i], 0, _MAX_DEBT_PRINCIPAL_);

            try
                anzaTokenHarness.exposed__mint(
                    lender,
                    _lenderTokenId,
                    _amounts[i]
                )
            {
                // Write/append debt to debt book if successful mint.
                if (_debtBalance == 0) {
                    debtBookHarness.exposed__writeDebt(
                        address(anzaTokenHarness),
                        collateralId
                    );

                    collateralVaultHarness.exposed__record(
                        admin,
                        address(anzaTokenHarness),
                        collateralId,
                        debtBookHarness.totalDebts(),
                        0
                    );
                } else {
                    debtBookHarness.exposed__appendDebt(
                        address(anzaTokenHarness),
                        collateralId
                    );

                    collateralVaultHarness.exposed__record(
                        admin,
                        address(anzaTokenHarness),
                        collateralId,
                        debtBookHarness.totalDebts(),
                        _debtCount
                    );
                }

                // Accumulate debt balance for later validation.
                _debtBalance += _amounts[i];
                _debtIds[_debtCount - 1] = debtBookHarness.totalDebts();
                _collateralNonces[_debtCount - 1] = _debtCount;
            } catch (bytes memory _err) {
                // If fail, revert debt count to previous value.
                --_debtCount;

                if (_amounts[i] == 0) {
                    assertTrue(
                        bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                        "0 :: 'illegal mint selector failure' expected."
                    );
                } else {
                    unexpectedFail(
                        "not 'illegal mint selector failure', should not fail",
                        _err
                    );
                }
            }
        }

        // Test collateral debt at calls with indexes.
        for (uint256 i; i < _amounts.length; ++i) {
            try debtBookHarness.collateralDebtAt(_debtIds[i], i) returns (
                uint256 _debtId,
                uint256 _collateralNonce
            ) {
                assertEq(
                    _debtId,
                    _debtIds[i],
                    "1 :: debt ID does not equal expected value."
                );

                assertEq(
                    _collateralNonce,
                    _collateralNonces[i],
                    "2 :: collateral nonce does not equal expected value."
                );
            } catch (bytes memory _err) {
                if (_debtCount == 0 || i >= _debtCount) {
                    assertEq(
                        _err,
                        stdError.indexOOBError,
                        "3 :: 'index out of bounds' expected."
                    );
                } else {
                    unexpectedFail(
                        "not 'index out of bounds', should not fail",
                        _err
                    );
                }
            }
        }

        // Test collateral debt at calls with max uint256.
        // Should return last collateral debt.
        try
            debtBookHarness.collateralDebtAt(
                _debtIds[_debtCount - 1],
                type(uint256).max
            )
        returns (uint256 _debtId, uint256 _collateralNonce) {
            assertEq(
                _debtId,
                _debtIds[_debtCount - 1],
                "4 :: debt ID does not equal expected value."
            );

            assertEq(
                _collateralNonce,
                _collateralNonces[_debtCount - 1],
                "5 :: collateral nonce does not equal expected value."
            );
        } catch (bytes memory _err) {
            if (_debtCount == 0) {
                assertEq(
                    _err,
                    stdError.arithmeticError,
                    "6 :: 'arithmetic over/underflow' expected."
                );
            } else {
                unexpectedFail(
                    "not 'arithmetic over/underflow'', should not fail",
                    _err
                );
            }
        }
    }

    /* ----------- DebtBook.collateralNonce() ----------- */
    /**
     * Fuzz test the collateral nonce function with random debt amojunts.
     *
     * @notice Test Function:
     *  function collateralNonce(
     *      address _collateralAddress,
     *      uint256 _collateralId
     *  ) external view returns (uint256)
     *
     * @param _amount The debt amounts.
     *
     * @dev Full pass if the initial collateral nonce is equal to 1.
     * @dev Full pass if the collateral nonce is equal to the expected value.
     */
    function testDebtBook__FuzzAmounts_CollateralNonce(uint8 _amount) public {
        uint256 _expectedNonce = 1;

        assertEq(
            debtBookHarness.collateralNonce(
                address(anzaTokenHarness),
                collateralId
            ),
            _expectedNonce++,
            "0 :: collateral nonce expected to be 1."
        );

        for (uint256 i; i < _amount; ++i) {
            i == 0
                ? debtBookHarness.exposed__writeDebt(
                    address(anzaTokenHarness),
                    collateralId
                )
                : debtBookHarness.exposed__appendDebt(
                    address(anzaTokenHarness),
                    collateralId
                );

            assertEq(
                debtBookHarness.collateralNonce(
                    address(anzaTokenHarness),
                    collateralId
                ),
                _expectedNonce,
                StringUtils.concatTestStr(
                    "collateral nonce expected to be",
                    i + 1,
                    _expectedNonce
                )
            );

            ++_expectedNonce;
        }
    }

    /**
     * Fuzz test the collateral nonce function with random collateral.
     *
     * @notice Test Function:
     *  function collateralNonce(
     *      address _collateralAddress,
     *      uint256 _collateralId
     * ) external view returns (uint256)
     *
     * @param _collaterals The collateralAddresses, collateralIds, and amounts (unused).
     *
     * @dev Full pass if the initial collateral nonce is equal to 1.
     * @dev Full pass if the collateral nonce is equal to the expected value.
     * @dev Caught fail/pass if the collateral address is address 0 and the function
     * reverts with the expected error.
     */
    function testDebtBook__FuzzCollateral_CollateralNonce(
        FuzzCollateralInput[] memory _collaterals
    ) public {
        uint256 _amount = 24;
        uint256 _maxCollateralLoops = 10;

        uint256 _collateralLoops = _collaterals.length > _maxCollateralLoops
            ? _maxCollateralLoops
            : _collaterals.length;
        vm.assume(_collateralLoops > 0);

        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];

            // Set expected initial collateral nonce.
            try
                debtBookHarness.collateralNonce(
                    _collateral.collateralAddress,
                    _collateral.collateralId
                )
            returns (uint256 _collateralNonce) {
                assertEq(
                    _collateralNonce,
                    1,
                    "0 :: collateral nonce expected to be 1."
                );
            } catch (bytes memory _err) {
                if (_collateral.collateralAddress == address(0)) {
                    assertTrue(
                        bytes4(_err) == _INVALID_COLLATERAL_SELECTOR_,
                        "0 :: 'invalid collateral selector failure' expected."
                    );
                } else {
                    unexpectedFail(
                        "address not address(0), should not fail",
                        _err
                    );
                }
            }
        }

        // Write debt for hardcoded amount of times.
        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];

            if (_collateral.collateralAddress == address(0)) continue;

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            for (uint256 i; i < _amount; ++i) {
                i == 0
                    ? debtBookHarness.exposed__writeDebt(
                        _collateral.collateralAddress,
                        _collateral.collateralId
                    )
                    : debtBookHarness.exposed__appendDebt(
                        _collateral.collateralAddress,
                        _collateral.collateralId
                    );

                _collateralData.collateralNonces.push(i + 1);
            }
        }

        // Check collateral nonce for each collateral.
        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];

            try
                debtBookHarness.collateralNonce(
                    _collateral.collateralAddress,
                    _collateral.collateralId
                )
            returns (uint256 _collateralNonce) {
                assertEq(
                    _collateralNonce,
                    _amount + 1,
                    StringUtils.concatTestStr(
                        "collateral nonce expected to be",
                        j + 1,
                        _amount + 1
                    )
                );
            } catch (bytes memory _err) {
                if (_collateral.collateralAddress == address(0)) {
                    assertTrue(
                        bytes4(_err) == _INVALID_COLLATERAL_SELECTOR_,
                        "0 :: 'invalid collateral selector failure' expected."
                    );
                } else {
                    unexpectedFail(
                        "address not address(0), should not fail",
                        _err
                    );
                }
            }
        }
    }

    /**
     * Fuzz test the collateral nonce function with random collateral and debt amounts.
     *
     * @notice Test Function:
     *  function collateralNonce(
     *      address _collateralAddress,
     *      uint256 _collateralId
     *  ) external view returns (uint256)
     *
     * @param _collaterals The collateralAddresses, collateralIds, and amounts.
     *
     * @dev Full pass if the collateral nonce is equal to the expected value.
     * @dev Caught fail/pass if the collateral address is address 0 and the function
     */
    function testDebtBook__Fuzz_CollateralNonce(
        FuzzCollateralInput[] memory _collaterals
    ) public {
        uint256 _maxCollateralLoops = 10;
        uint256 _maxAmountLoops = 10;

        // Limit number of collateral loops for time.
        uint256 _collateralLoops = _collaterals.length > _maxCollateralLoops
            ? _maxCollateralLoops
            : _collaterals.length;
        vm.assume(_collateralLoops > 0);

        // Test intitial collateral nonce.
        // Performed in previous tests. Duplication not needed.

        // Write debt for hardcoded amount of times.
        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];

            if (_collateral.collateralAddress == address(0)) continue;

            // Limit number of amount loops for time.
            uint256 _amountLoops = _collateral.amounts.length > _maxAmountLoops
                ? _maxAmountLoops
                : _collateral.amounts.length;

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            for (uint256 i; i < _amountLoops; ++i) {
                i == 0
                    ? debtBookHarness.exposed__writeDebt(
                        _collateral.collateralAddress,
                        _collateral.collateralId
                    )
                    : debtBookHarness.exposed__appendDebt(
                        _collateral.collateralAddress,
                        _collateral.collateralId
                    );

                _collateralData.collateralNonces.push(i + 1);
                ++_collateralData.debtCount;
            }
        }

        // Check collateral nonce for each collateral.
        for (uint256 j; j < _collateralLoops; ++j) {
            FuzzCollateralInput memory _collateral = _collaterals[j];

            FuzzCollateralStorage storage _collateralData = collateralData[
                _collateral.collateralAddress
            ][_collateral.collateralId];

            try
                debtBookHarness.collateralNonce(
                    _collateral.collateralAddress,
                    _collateral.collateralId
                )
            returns (uint256 _collateralNonce) {
                assertEq(
                    _collateralNonce,
                    _collateralData.debtCount + 1,
                    StringUtils.concatTestStr(
                        "collateral nonce expected to be",
                        j + 1,
                        _collateralData.debtCount + 1
                    )
                );
            } catch (bytes memory _err) {
                if (_collateral.collateralAddress == address(0)) {
                    assertTrue(
                        bytes4(_err) == _INVALID_COLLATERAL_SELECTOR_,
                        "0 :: 'invalid collateral selector failure' expected."
                    );
                } else {
                    unexpectedFail(
                        "address not address(0), should not fail",
                        _err
                    );
                }
            }
        }
    }
}
