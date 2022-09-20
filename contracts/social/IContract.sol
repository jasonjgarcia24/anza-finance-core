// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

interface IContract {
    struct LoanContract {
        address borrower;
        address lender;
        address tokenContract;
        uint256 tokenId;
        uint256 priority;
        uint256 principal;
        uint256 fixedInterestRate;
        uint256 duration;
        uint256 balance;
    }
}