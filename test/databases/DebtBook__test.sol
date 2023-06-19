// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import {_MAX_DEBT_PRINCIPAL_, _MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_ILLEGAL_MINT_SELECTOR_, _INVALID_TOKEN_ID_SELECTOR_} from "@custom-errors/StdAnzaTokenErrors.sol";
import {_INVALID_COLLATERAL_SELECTOR_} from "@custom-errors/StdLoanErrors.sol";

import {DebtBook} from "@lending-databases/DebtBook.sol";
import {AnzaToken} from "@base/token/AnzaToken.sol";
import {LoanTreasurey} from "@base/LoanTreasurey.sol";
import {CollateralVault} from "@base/CollateralVault.sol";
import {AnzaDebtStorefront} from "@base/storefronts/AnzaDebtStorefront.sol";
import {AnzaSponsorshipStorefront} from "@base/storefronts/AnzaSponsorshipStorefront.sol";
import {AnzaRefinanceStorefront} from "@base/storefronts/AnzaRefinanceStorefront.sol";

import {Setup} from "@test-base/Setup__test.sol";
import {AnzaTokenHarness} from "@test-tokens/AnzaToken__test.sol";

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

    function setUp() public virtual override {
        // Deploy DebtBook
        debtBookHarness = new DebtBookHarness();

        super.setUp();
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
    AnzaTokenHarness public anzaTokenHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy AnzaToken
        anzaTokenHarness = new AnzaTokenHarness();

        // Set AnzaToken access control roles
        anzaTokenHarness.grantRole(_LOAN_CONTRACT_, address(loanContract));
        anzaTokenHarness.grantRole(_TREASURER_, address(loanTreasurer));
        anzaTokenHarness.grantRole(
            _COLLATERAL_VAULT_,
            address(collateralVault)
        );

        // Set LoanContract access control roles
        loanContract.setAnzaToken(address(anzaTokenHarness));

        // Set LoanTreasurey access control roles
        loanTreasurer.setAnzaToken(address(anzaTokenHarness));

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

        vm.stopPrank();
    }

    function testDebtBook__FuzzTokenId_DebtBalance(
        uint256 _amount,
        uint256 _tokenId
    ) public {
        uint256 _debtId = anzaTokenHarness.debtId(_tokenId);

        try anzaTokenHarness.anzaMintViaHarness(lender, _tokenId, _amount) {
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
                emit log("Error: amount greater than 0, should not fail.");
                emit log_named_bytes("Unexpected error", _err);
                assertTrue(false);
            }
        }
    }

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
                emit log("Error: debt ID within range, should not fail.");
                emit log_named_bytes("Unexpected error", _err);
                fail();
            }
        }
    }

    function testDebtBook__FuzzTokenId_LenderDebtBalance(
        uint256 _amount,
        uint256 _tokenId
    ) public {
        uint256 _debtId = anzaTokenHarness.debtId(_tokenId);

        try anzaTokenHarness.anzaMintViaHarness(lender, _tokenId, _amount) {
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
                    emit log("Error: lender debt balance should not fail.");
                    emit log_named_string("Unexpected error", _err);
                    fail();
                }
            }
        } catch (bytes memory _err) {
            if (_amount == 0) {
                assertTrue(
                    bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                    "0 :: 'illegal mint selector failure' expected."
                );
            } else {
                emit log("Error: amount greater than 0, should not fail.");
                emit log_named_bytes("Unexpected error", _err);
                assertTrue(false);
            }
        }
    }

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

        try anzaTokenHarness.anzaMintViaHarness(borrower, _tokenId, _amount) {
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
                    emit log("Error: borrower debt balance should not fail.");
                    emit log_named_string("Unexpected error", _err);
                    fail();
                }
            }
        } catch (bytes memory _err) {
            if (_amount == 0) {
                assertTrue(
                    bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                    "0 :: 'illegal mint selector failure' expected."
                );
            } else {
                emit log("Error: amount greater than 0, should not fail.");
                emit log_named_bytes("Unexpected error", _err);
                assertTrue(false);
            }
        }
    }

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
        uint256[] memory _amounts
    ) public {
        uint256 _debtBalance;
        uint256 _debtCount;

        for (uint256 i; i < _amounts.length; ++i) {
            uint256 _lenderTokenId = anzaTokenHarness.lenderTokenId(
                ++_debtCount
            );
            _amounts[i] = bound(_amounts[i], 0, _MAX_DEBT_PRINCIPAL_);

            try
                anzaTokenHarness.anzaMintViaHarness(
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
            } catch (bytes memory _err) {
                if (_amounts[i] == 0) {
                    // If fail, revert debt count to previous value.
                    --_debtCount;

                    assertTrue(
                        bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                        "0 :: 'illegal mint selector failure' expected."
                    );
                } else {
                    emit log("Error: amount greater than 0, should not fail.");
                    emit log_named_bytes("Unexpected error", _err);
                    assertTrue(false);
                }
            }
        }

        // Only perform comparison if there was a debt balance.
        if (_debtCount > 0) {
            assertEq(
                debtBookHarness.collateralDebtBalance(
                    address(anzaTokenHarness),
                    collateralId
                ),
                _debtBalance,
                "1 :: collateral debt balance does not equal expected value."
            );
        }
    }

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
                anzaTokenHarness.anzaMintViaHarness(
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
                _debtIds[_debtCount - 1] = _debtCount;
                _collateralNonces[_debtCount - 1] = _debtCount;
            } catch (bytes memory _err) {
                if (_amounts[i] == 0) {
                    // If fail, revert debt count to previous value.
                    --_debtCount;

                    assertTrue(
                        bytes4(_err) == _ILLEGAL_MINT_SELECTOR_,
                        "0 :: 'illegal mint selector failure' expected."
                    );
                } else {
                    emit log("Error: amount greater than 0, should not fail.");
                    emit log_named_bytes("Unexpected error", _err);
                    assertTrue(false);
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
            returns (uint256 _debtId, uint256 _collateranNonce) {
                assertEq(
                    _debtId,
                    _debtIds[i],
                    "1 :: debt ID does not equal expected value."
                );

                assertEq(
                    _collateranNonce,
                    _collateralNonces[i],
                    "2 :: collateral nonce does not equal expected value."
                );
            } catch (bytes memory _err) {
                if (_debtCount == 0 || i >= _debtCount) {
                    assertTrue(
                        bytes4(_err) == _INVALID_COLLATERAL_SELECTOR_,
                        "3 :: 'invalid collateral selector failure' expected."
                    );
                } else {
                    emit log("Error: should not fail.");
                    emit log_named_bytes("Unexpected error", _err);
                    assertTrue(false);
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
        returns (uint256 _debtId, uint256 _collateranNonce) {
            assertEq(
                _debtId,
                _debtIds[_debtCount - 1],
                "4 :: debt ID does not equal expected value."
            );

            assertEq(
                _collateranNonce,
                _collateralNonces[_debtCount - 1],
                "5 :: collateral nonce does not equal expected value."
            );
        } catch (bytes memory _err) {
            if (_debtCount == 0) {
                assertTrue(
                    bytes4(_err) == _INVALID_COLLATERAL_SELECTOR_,
                    "6 :: 'invalid collateral selector failure' expected."
                );
            } else {
                emit log("Error: should not fail.");
                emit log_named_bytes("Unexpected error", _err);
                assertTrue(false);
            }
        }
    }
}
