// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

interface ILoanContract {

    function initialize(
        address _loanTreasurer,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _priority,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) external;

    function setLender() external;

    /**
     * @dev Transfers owners of the collateral to the loan contract.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_BORROWER_ROLE_`.
     * - The loan contract state must be `LoanState.NONLEVERAGED`.
     *
     * Emits {LoanStateChanged} event.
     */
    function depositCollateral() external;

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawFunds() external;

    /**
     * @dev Withdraw collateral token.
     *
     */
    function withdrawNft() external;

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     */
    function withdrawSponsorship() external;

    function sign() external;

    /**
     * @dev Revoke collateralized token and revoke LoanContract approval. This
     * effectively renders the LoanContract closed.
     *
     * Requirements:
     *
     * - The caller must have been granted the _COLLATERAL_OWNER_ROLE_.
     *
     */
    function close() external;

    function __sign() external;
}
