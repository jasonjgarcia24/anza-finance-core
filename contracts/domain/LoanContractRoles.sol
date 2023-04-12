// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* ------------------------------------------------ *
 *              Loan Contract Roles                 *
 * ------------------------------------------------ */
bytes32 constant ADMIN = keccak256("ADMIN");
bytes32 constant FACTORY = keccak256("FACTORY");
bytes32 constant LOAN_CONTRACT = keccak256("LOAN_CONTRACT");
bytes32 constant OWNER = keccak256("OWNER");
bytes32 constant TREASURER = keccak256("TREASURER");
bytes32 constant COLLECTOR = keccak256("COLLECTOR");
bytes32 constant DEBT_STOREFRONT = keccak256("DEBT_STOREFRONT");
bytes32 constant CLOSED_BIN = keccak256("CLOSED_BIN");
