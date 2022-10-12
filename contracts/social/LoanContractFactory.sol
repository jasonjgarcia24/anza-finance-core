// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ILoanContract.sol";
import "hardhat/console.sol";

contract LoanContractFactory {
    using Counters for Counters.Counter;

    /**
     * @dev Emitted when a loan lender is changed.
     */
    event LoanContractCreated(
        address indexed loanContract,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    Counters.Counter loanId;
    address immutable public loanTreasurer;
    address immutable public loanCollector;

    constructor (address _loanTreasurer, address _loanCollector) {
        loanTreasurer = _loanTreasurer;
        loanCollector = _loanCollector;
    }

    function createLoanContract(
        address _loanContract,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) external {
        require(
            _tokenContract != address(0),
            "Collateral cannot be address 0."
        );

        // Create new loan contract
        address _clone = Clones.clone(_loanContract);

        ILoanContract(payable(_clone)).initialize(
            loanTreasurer,
            loanCollector,
            _tokenContract,
            _tokenId,
            loanId.current(),
            _principal,
            _fixedInterestRate,
            _duration
        );

        // Transfer collateral to LoanContract
        IERC721(_tokenContract).approve(_clone, _tokenId);
        ILoanContract(payable(_clone)).depositCollateral();
        loanId.increment();

        emit LoanContractCreated(_clone, _tokenContract, _tokenId);
    }

    function getNextDebtId() external view returns (uint256) {
        return loanId.current();
    }

    fallback() external {}
}
