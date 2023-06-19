// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ILoanManager {
    event LoanTermsRevoked(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );

    event LoanTermsReinstated(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );

    function maxRefinances() external pure returns (uint256);

    function updateLoanState(uint256 _debtId) external returns (bool);

    function verifyLoanActive(uint256 _debtId) external view;

    function verifyLoanNotExpired(uint256 _debtId) external view;

    function checkLoanActive(uint256 _debtId) external view returns (bool);

    function checkLoanDefault(uint256 _debtId) external view returns (bool);

    function checkLoanExpired(uint256 _debtId) external view returns (bool);

    function checkLoanClosed(uint256 _debtId) external view returns (bool);
}
