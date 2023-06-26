// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanTreasurey {
    function sponsorPayment(
        address _sponsor,
        uint256 _debtId
    ) external payable returns (bool);

    function depositPayment(uint256 _debtId) external payable returns (bool);

    function withdrawFromBalance(uint256 _amount) external returns (bool);

    function withdrawCollateral(uint256 _debtId) external returns (bool);
}
