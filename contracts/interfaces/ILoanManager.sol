// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAnzaToken.sol";
import "./ILoanTreasurey.sol";

interface ILoanManager {
    error InvalidLoanParameter(bytes4 parameter);

    function loanTreasurer() external returns (address);

    function anzaToken() external returns (address);

    function maxRefinances() external returns (uint256);

    function setLoanTreasurer(address _loanTreasurer) external;

    function setAnzaToken(address _anzaToken) external;

    function setMaxRefinances(uint256 _maxRefinances) external;

    function updateLoanState(uint256 _debtId) external;

    function verifyLoanActive(uint256 _debtId) external view;

    function checkLoanActive(uint256 _debtId) external view returns (bool);

    function checkLoanDefault(uint256 _debtId) external view returns (bool);

    function checkLoanExpired(uint256 _debtId) external view returns (bool);
}
