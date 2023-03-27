// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAnzaDebtToken.sol";
import "./interfaces/ILoanTreasurey.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

import {LibContractGlobals as Globals, LibContractStates as States, LibContractAssess as Assess} from "./libraries/LibContractMaster.sol";
import {LibLoanTreasurey as Treasurey, TreasurerUtils as Utils} from "./libraries/LibContractTreasurer.sol";

import "./interfaces/ILoanContract.sol";
import {StateControlUint256 as scUint, StateControlAddress as scAddress} from "../utils/StateControl.sol";

contract LoanTreasurey is Ownable, ERC165, ILoanTreasurey {
    address private debtTokenAddress;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(ILoanTreasurey).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ILoanTreasurey-makePayment}.
     */
    function makePayment(address _loanContractAddress) external payable {
        (bool _success, ) = _loanContractAddress.call{value: msg.value}(
            abi.encodeWithSignature("makePayment()")
        );

        require(_success, "Payment failed.");
    }

    /**
     * @dev See {ILoanTreasurey-withdrawFunds}.
     */
    function withdrawFunds(address _loanContractAddress) external {
        ILoanContract(_loanContractAddress).withdrawFunds(_msgSender());
    }

    /**
     * @dev See {ILoanTreasurey-setDebtTokenAddress}
     */
    function setDebtTokenAddress(address _debtTokenAddress) external onlyOwner {
        debtTokenAddress = _debtTokenAddress;
    }

    /**
     * @dev See {ILoanTreasurey-getBalance}
     */
    function getBalance(address _loanContractAddress)
        external
        view
        returns (uint256)
    {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        return _loanContract.getBalance();
    }

    /**
     * @dev See {ILoanTreasurey-updateBalance}
     */
    function updateBalance(address _loanContractAddress) external onlyOwner {
        ILoanContract(_loanContractAddress).updateBalance();
    }

    /**
     * @dev See {ILoanTreasurey-assessMaturity}
     */
    function assessMaturity(address _loanContractAddress) external onlyOwner {
        States.LoanState _assessedState = Treasurey.assessMaturity_(
            _loanContractAddress
        );

        if (_assessedState == States.LoanState.DEFAULT) {
            Treasurey.initDefault_(_loanContractAddress);
        }
    }

    /**
     * @dev See {ILoanTreasurey-issueDebtToken}
     */
    function issueDebtToken(
        address _loanContractAddress,
        address _recipient,
        string calldata _debtURI
    ) external {
        require(debtTokenAddress != address(0), "Debt token not set");
        States.checkActiveState_(_loanContractAddress);
        _checkRole(Globals._PARTICIPANT_ROLE_, _loanContractAddress);

        // Get LoanContract balance and debt ID
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        uint256 _balance = _loanContract.getBalance();
        (, uint256 _debtId, ) = _loanContract.loanGlobals();

        // Issue ADT to recipient
        IAnzaDebtToken(debtTokenAddress).mintDebt(
            _recipient,
            _debtId,
            _balance,
            _debtURI
        );

        emit DebtTokenIssued(
            _msgSender(),
            debtTokenAddress,
            _debtId,
            _recipient
        );
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address _loanContractAddress)
        internal
        view
    {
        if (!ILoanContract(_loanContractAddress).hasRole(role, _msgSender())) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_msgSender()), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    fallback() external {}
}
