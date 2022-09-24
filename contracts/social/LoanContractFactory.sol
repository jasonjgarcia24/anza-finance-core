// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LoanContract.sol";

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

    mapping(address => mapping(uint256 => Counters.Counter)) private loanPriorityMap;
    
    function createLoanContract(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration
    ) public {
        require(_tokenContract != address(0), "Collateral cannot be address 0.");

        // Create new loan contract
        loanPriorityMap[_tokenContract][_tokenId].increment();

        LoanContract _loanContract = new LoanContract(
            _tokenContract,
            _tokenId,
            loanPriorityMap[_tokenContract][_tokenId].current(),
            _principal,
            _fixedInterestRate,
            _duration
        );

        // Transfer collateral to LoanContract
        address _loanContractAddress = address(_loanContract);

        IERC721(_tokenContract).approve(_loanContractAddress, _tokenId);
        LoanContract(payable(_loanContractAddress)).depositCollateral();

        emit LoanContractCreated(_loanContractAddress, _tokenContract, _tokenId);
    }
}
