// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILoanTreasurey {
    /**
     * @dev Emitted when deb token(s) are distributed.
     */
    event DebtTokenIssued(
        address indexed from,
        address indexed debtTokenAddress,
        uint256 indexed debtTokenId,
        address to
    );

    /**
     * @dev Make payment to `_loanContractAddress`.
     * @param _loanContractAddress The LoanContract address managing the loan.
     * 
     * Requirements: None
     */
    function makePayment(address _loanContractAddress) external payable;

    /**
     * @dev Withdraw funds to `msg.sender`. See {ILoanContract-withdrawFunds}
     * @param _loanContractAddress The LoanContract address managing the loan.
     * 
     * Requirements: None
     */
    function withdrawFunds(address _loanContractAddress) external;

    /**
     * @dev Set the `debtTokenAddress` state variable with the AnzaDebtToken address.
     * @param _debtTokenAddress The AnzaDebtToken address.
     * 
     * Requirements:
     * 
     * - Only the owner must be the caller.
     */
    function setDebtTokenAddress(address _debtTokenAddress) external;

    /**
     * @dev Get the updated LoanContract balance from `_loanContractAddress`. See
     * {LibContractTreasurer:LibLoanTreasurey-getBalance_}
     * @param _loanContractAddress The LoanContract address managing the loan.
     * @return _balance The LoanContract balance plus interest.
     * 
     * Requirements: None
     */
    function getBalance(address _loanContractAddress) external view returns (uint256 _balance);

    /**
     * @dev Update the LoanContract balance. See 
     * {LibContractTreasurer:LibLoanTreasurey-updateBalance_}.
     * @param _loanContractAddress The LoanContract address managing the loan.
     * 
     * Requirements:
     * 
     * - Only the owner must be the caller.
     */
    function updateBalance(address _loanContractAddress) external;

    /**
     * @dev Assess loan maturity. If loan is defaulted, this function will initiate the
     * LoanContract default function.
     * @param _loanContractAddress The LoanContract address managing the loan.
     * 
     * Requirements:
     * 
     * - The loan must be in an active state as defined in 
     * {LibContractMaster.LibContractAssess.checkActiveState_()}
     */
    function assessMaturity(address _loanContractAddress) external;

    /**
     * @dev Mint and issue the ADT token for the `debtId` (i.e. tokenId).
     * @param _loanContractAddress The LoanContract address managing the loan.
     * @param _recipient The reciever of the minted ADT.
     * @param _debtURI The IPFS CID with the minted ADT metadata.
     * 
     * Requirements:
     *
     * - The `debtTokenAddress` must not be address(0).
     * - The LoanContract state must be between FUNDED and PAID exclusively.
     * - The caller must have been granted the _PARTICIPANT_ROLE_.
     * 
     * Emits {DebtTokenIssued} event.
     */
    function issueDebtToken(
        address _loanContractAddress,
        address _recipient,
        string memory _debtURI
    ) external;
}