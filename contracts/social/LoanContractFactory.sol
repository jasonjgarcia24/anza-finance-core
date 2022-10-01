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

    struct LoanStruct {
        Counters.Counter loanId;
        address[] clones;
    }

    mapping(address => mapping(uint256 => LoanStruct)) private loanMap;

    address immutable public loanTreasurer;

    constructor (address _loanTreasurer) {
        loanTreasurer = _loanTreasurer;
    }

    function createLoanContract(
        address _loanContract,
        address _loanTreasurer,
        address _loanCollector,
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

        loanMap[_tokenContract][_tokenId].loanId.increment();
        loanMap[_tokenContract][_tokenId].clones.push(_clone);

        ILoanContract(payable(_clone)).initialize(
            _loanTreasurer,
            _loanCollector,
            _tokenContract,
            _tokenId,
            __getCurrentPriority(_tokenContract, _tokenId),
            _principal,
            _fixedInterestRate,
            _duration
        );

        // // Transfer collateral to LoanContract
        IERC721(_tokenContract).approve(_clone, _tokenId);
        ILoanContract(payable(_clone)).depositCollateral();

        emit LoanContractCreated(_clone, _tokenContract, _tokenId);
    }

    function __getCurrentPriority(address _tokenContract, uint256 _tokenId)
        private
        view
        returns (uint256)
    {
        return loanMap[_tokenContract][_tokenId].loanId.current() - 1;
    }
}
