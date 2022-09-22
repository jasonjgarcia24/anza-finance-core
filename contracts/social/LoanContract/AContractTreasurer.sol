// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "./AContractAffirm.sol";

abstract contract AContractTreasurer is AContractAffirm {
    using Address for address payable;

    /**
     * @dev Emitted when loan contract funding is withdrawn.
     */
    event Deposited(
        address indexed payee,
        uint256 weiAmount
    );

    /**
     * @dev Emitted when loan contract funding is withdrawn.
     */
    event Withdrawn(
        address indexed payee,
        uint256 weiAmount
    );

    /**
     * @dev Funds the loan contract.
     *
     * Requirements:
     *
     * - The caller must have been granted the `_LENDER_ROLE_`.
     * - The loan contract state must be `LoanState.SPONSORED`.
     *
     * Emits a {Deposited} event.
     */
    function _fundLoan() public payable onlyRole(_LENDER_ROLE_) {
        require(
            _msgSender() == lender,
            "The caller must be the lender."
        );
        require(
            state == LoanState.SPONSORED,
            "The loan state must be LoanState.SPONSORED."
        );

        accountBalance[lender] += msg.value;
        require(
            accountBalance[lender] >= principal,
            "The caller's account balance is insufficient."
        );

        accountBalance[lender] -= principal;
        emit Deposited(lender, msg.value);
    }
    
    /**
     * @dev Defunds the loan contract.
     *
     * Requirements:
     *
     * - The loan contract state must be LoanState.FUNDED.
     *
     */
    function _defundLoan() internal {
        require(
            state == LoanState.FUNDED,
            "The loan state must be LoanState.FUNDED."
        );

        accountBalance[lender] += principal;
    }

    /**
     * @dev Withdraws funds from loan.
     * 
     * Requirements: NONE
     * 
     * Emits a {Withdrawn} event.
     */
    function _withdrawFunds(address payable _payee) internal {     
        uint256 _payment = accountBalance[_payee];
        accountBalance[_payee] = 0;

        _payee.sendValue(_payment);

        emit Withdrawn(_payee, _payment);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    receive() external payable onlyRole(_PARTICIPANT_ROLE_) {        
        accountBalance[_msgSender()] += msg.value;
        payable(address(this)).transfer(msg.value);
    }
}