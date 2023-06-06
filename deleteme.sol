function getCollateralDebtCount(
    address _collateralAddress,
    uint256 _collateralId
) public view returns (uint256) {
    return __debtIds[_collateralAddress][_collateralId].length;
}

function getCollateralDebtIndex(
    address _collateralAddress,
    uint256 _collateralId,
    uint256 _debtId
) public view returns (uint256) {
    uint256[] memory _debtIds = __debtIds[_collateralAddress][_collateralId];

    for (uint256 i; i < _debtIds.length; ) {
        if (_debtIds[i].debtId == _debtId) return i;

        unchecked {
            ++i;
        }
    }

    revert InvalidCollateral();
}

function getCollateralDebtAt(
    address _collateralAddress,
    uint256 _collateralId,
    uint256 _index
) public view returns (DebtMap memory) {
    uint256[] memory _debtIds = __debtIds[_collateralAddress][_collateralId];

    if (_debtIds.length < _index || _index == 0) revert InvalidIndex();

    return _debtIds[_index];
}
