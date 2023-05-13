// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract AnzaGovernanceToken is ERC20Votes {
    constructor() ERC20("AnzaGovernanceToken", "AGT") ERC20Permit("AnzaGovernanceToken") {}

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(_from, _to, _amount);
    }

    function _mint(address _to, uint256 _amount) internal override(ERC20Votes) {
        super._mint(_to, _amount);
    }

    function _burn(
        address _account,
        uint256 _amount
    ) internal override(ERC20Votes) {
        super._burn(_account, _amount);
    }
}
