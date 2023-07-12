// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPaymentBookAccessController {
    function anzaToken() external view returns (address);

    function setAnzaToken(address _anzaTokenAddress) external;
}
