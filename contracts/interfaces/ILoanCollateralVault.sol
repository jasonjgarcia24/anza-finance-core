// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

interface ILoanCollateralVault {
    error UnallowedDeposit();
    error UnallowedWithdrawal();
    error IllegalDebtId();

    event DepositedCollateral(
        address indexed from,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    event WithdrawnCollateral(
        address indexed to,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    struct Collateral {
        address collateralAddress;
        uint256 collateralId;
        bool vault;
    }

    function totalCollateral() external view returns (uint256);

    function loanContract() external view returns (address);

    function getCollateral(
        uint256 _debtId
    ) external view returns (Collateral memory);

    function setLoanContract(address _loanContract) external;

    function setCollateral(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) external;

    function depositAllowed(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) external returns (bool);

    function withdrawalAllowed(
        address _to,
        uint256 _debtId
    ) external view returns (bool);

    function withdraw(
        address _loanContractAddress,
        uint256 _debtId
    ) external returns (bool);
}
