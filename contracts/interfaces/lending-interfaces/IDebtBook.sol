// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IDebtBook {
    struct DebtMap {
        uint256 debtId;
        uint256 collateralNonce;
    }

    function totalDebts() external returns (uint256);

    function debtBalance(uint256 debtId) external view returns (uint256);

    function lenderDebtBalance(
        uint256 _debtId
    ) external view returns (uint256 debtBalance);

    function borrowerDebtBalance(
        uint256 _debtId
    ) external view returns (uint256 debtBalance);

    function collateralDebtBalance(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256 debtBalance);

    function collateralDebtCount(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function collateralDebtAt(
        uint256 _debtId,
        uint256 _index
    ) external view returns (uint256 debtId, uint256 collateralNonce);

    function collateralDebtAt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _index
    ) external view returns (uint256 debtId, uint256 collateralNonce);

    function collateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256 collateralNonce);
}
