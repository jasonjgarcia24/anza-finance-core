// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AProposalAffirm.sol";

abstract contract AProposalTreasurer is AProposalAffirm {    
    mapping(address => uint256) internal accountWithdrawalLimit;

    // /**
    //  * @dev Funds the loan proposal.
    //  *
    //  * Requirements:
    //  *
    //  * - The caller must be the lender.
    //  * - The loan proposal state must be `LoanState.SPONSORED`.
    //  *
    //  */
    // function _fundLoanProposal(
    //     address _tokenContract,
    //     uint256 _tokenId,
    //     uint256 _loanId
    // ) internal {
    //     LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
    //         _tokenId
    //     ][_loanId];

    //     require(
    //         msg.sender == _loanAgreement.lender,
    //         "The caller must be the lender."
    //     );
    //     require(
    //         _loanAgreement.state == LoanState.SPONSORED,
    //         "The loan state must be LoanState.SPONSORED."
    //     );

    //     accountWithdrawalLimit[_loanAgreement.lender] += msg.value;
    //     require(
    //         accountWithdrawalLimit[_loanAgreement.lender] >=
    //             _loanAgreement.principal,
    //         "The caller's account balance is insufficient."
    //     );

    //     LoanState _prevState = _loanAgreement.state;

    //     accountWithdrawalLimit[_loanAgreement.lender] -= _loanAgreement.principal;
    //     // payable(address(this)).transfer(_loanAgreement.principal);
    //     _loanAgreement.balance = _loanAgreement.principal;
    //     _loanAgreement.state = LoanState.FUNDED;

    //     emit LoanStateChanged(_prevState, _loanAgreement.state);
    // }

    /**
     * @dev Defunds the loan proposal.
     *
     * Requirements:
     *
     * - The caller must be the owner, approver, owner's operator, or lender.
     * - The loan proposal state must be LoanState.FUNDED.
     *
     */
    function _defundLoanProposal(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _loanId
    ) internal {
        LoanAgreement storage _loanAgreement = loanAgreements[_tokenContract][
            _tokenId
        ][_loanId];

        // require(
        //     msg.sender == _loanAgreement.lender ||
        //         isApproved(msg.sender, _tokenContract, _tokenId),
        //     "The caller must be the owner, approver, owner's operator, or lender."
        // );
        require(
            _loanAgreement.state == LoanState.FUNDED,
            "The loan state must be LoanState.FUNDED."
        );

        accountWithdrawalLimit[_loanAgreement.lender] += _loanAgreement.balance;
        _loanAgreement.balance = 0;
        _loanAgreement.state = LoanState.SPONSORED;
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

    receive() external payable {}
}