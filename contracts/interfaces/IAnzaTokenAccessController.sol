// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaTokenAccessController {
    function checkBorrowerOf(
        address _account,
        uint256 _debtId
    ) external view returns (bool);
}
