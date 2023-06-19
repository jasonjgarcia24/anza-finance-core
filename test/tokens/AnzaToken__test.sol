// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {AnzaToken} from "@base/token/AnzaToken.sol";

contract AnzaTokenHarness is AnzaToken {
    constructor() AnzaToken("www.anza-harness.io") {}

    function exposed__mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        _mint(_to, _id, _amount, _data);
    }

    function anzaMintViaHarness(
        address _receiver,
        uint256 _id,
        uint256 _amount
    ) external {
        _mint(_receiver, _id, _amount, "");
    }
}
