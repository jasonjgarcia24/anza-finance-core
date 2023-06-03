// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *              Loan Contract Roles                 *
 * ------------------------------------------------ */
bytes32 constant _ADMIN_ = keccak256("_ADMIN_");
bytes32 constant _LOAN_CONTRACT_ = keccak256("_LOAN_CONTRACT_");
bytes32 constant _TREASURER_ = keccak256("_TREASURER_");
bytes32 constant _COLLATERAL_VAULT_ = keccak256("_COLLATERAL_VAULT_");
bytes32 constant _COLLECTOR_ = keccak256("_COLLECTOR_");
bytes32 constant _DEBT_STOREFRONT_ = keccak256("_DEBT_STOREFRONT_");
