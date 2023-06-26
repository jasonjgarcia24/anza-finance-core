// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAnzaSponsorshipStorefrontAccessController {
    function anzaToken() external returns (address);

    function loanContract() external returns (address);

    function loanManager() external returns (address);
}
