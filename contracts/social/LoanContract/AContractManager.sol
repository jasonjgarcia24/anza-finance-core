// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AContractAffirm.sol";
import "./AContractNotary.sol";
import "./AContractTreasurer.sol";

abstract contract AContractManager is
    AContractAffirm,
    AContractNotary,
    AContractTreasurer
{}
