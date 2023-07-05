// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

bytes4 constant _UNALLOWED_DEPOSIT_ = 0x470c87cb; // bytes4(keccak256("UnallowedDeposit()"))
bytes4 constant _UNALLOWED_WITHDRAWAL_ = 0x87e8841d; // bytes4(keccak256("UnallowedWithdrawal()"))

library StdVaultErrors {
    /* ------------------------------------------------ *
     *         Collateral Vault Custom Errors           *
     * ------------------------------------------------ */
    error UnallowedDeposit();
    error UnallowedWithdrawal();
}
