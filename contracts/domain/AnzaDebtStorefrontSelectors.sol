// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *           Anza Debt Storefront Roles             *
 * ------------------------------------------------ */
bytes4 constant _BUY_DEBT_UNPUBLISHED_ = bytes4(
    keccak256("buyDebt(address,uint256,uint256,bytes)")
);
bytes4 constant _BUY_DEBT_PUBLISHED_ = bytes4(
    keccak256("buyDebt(address,uint256,uint256,uint256,bytes)")
);

/* ------------------------------------------------ *
 *        Anza Refinance Storefront Roles           *
 * ------------------------------------------------ */
bytes4 constant _REFINANCE_DEBT_UNPUBLISHED_ = bytes4(
    keccak256("refinanceDebt(uint256,uint256,bytes32,bytes)")
);
bytes4 constant _REFINANCE_DEBT_PUBLISHED_ = bytes4(
    keccak256("refinanceDebt(uint256,uint256,uint256,bytes32,bytes)")
);

/* ------------------------------------------------ *
 *        Anza Sponsorship Storefront Roles         *
 * ------------------------------------------------ */
bytes4 constant _SPONSOR_DEBT_UNPUBLISHED_ = bytes4(
    keccak256("sponsorDebt(uint256,uint256,bytes)")
);
bytes4 constant _SPONSOR_DEBT_PUBLISHED_ = bytes4(
    keccak256("sponsorDebt(uint256,uint256,uint256,bytes)")
);
