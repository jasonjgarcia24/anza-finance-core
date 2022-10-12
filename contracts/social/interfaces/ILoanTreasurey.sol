// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILoanTreasurey {
    function setDebtTokenAddress(address _debtTokenAddress) external;

    function makePayment(address _loanContract) external payable;

    function getBalance(address _loanContractAddress) external view returns (uint256);

    function assessMaturity(address _loanContractAddress) external;

    /**
     * @dev Issue debt token(s) to LoanContract. 
     *
     * Requirements:
     *
     * - The caller must have been granted the _PARTICIPANT_ROLE_.
     */
    function issueDebtToken(address _loanContractAddresss, string memory _debtURI) external;
}