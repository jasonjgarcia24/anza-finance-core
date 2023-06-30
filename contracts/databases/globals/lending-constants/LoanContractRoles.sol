// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *              Loan Contract Roles                 *
 * ------------------------------------------------ */
//  0xc9d3ed72b71767c9a467f79cf288882213fa725f40ea5b833a2b70350c4e0f12
bytes32 constant _ADMIN_ = keccak256("_ADMIN_");

// 0xaca95a87ebdd693d0a3734440ea0ab66d6317f6d32766e386292131defadde1a
bytes32 constant _LOAN_CONTRACT_ = keccak256("_LOAN_CONTRACT_");

// 0x8d24385f76974ce9574accf90a96cb183e175b097a0cdc49dd2ddd96f6374b72
bytes32 constant _TREASURER_ = keccak256("_TREASURER_");

// 0x3f3b124e7fbb383eba51953048c75da5e639b5f1d37462af6e4d67fb45851198
bytes32 constant _COLLATERAL_VAULT_ = keccak256("_COLLATERAL_VAULT_");

// 0x2d2f5bedf7d8f217c75277e619754ebd414a7ba49e87afb45bdec61736e10d68
bytes32 constant _COLLECTOR_ = keccak256("_COLLECTOR_");
