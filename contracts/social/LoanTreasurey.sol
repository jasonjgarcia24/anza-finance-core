// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAnzaDebtToken.sol";
import "./interfaces/ILoanTreasurey.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

import {
    LibContractGlobals as Globals,
    LibContractStates as States,
    LibContractAssess as Assess
} from "./libraries/LibContractMaster.sol";
import { 
    LibLoanTreasurey as Treasurey,
    TreasurerUtils as Utils
} from "./libraries/LibContractTreasurer.sol";

import "./interfaces/ILoanContract.sol";
import {
    StateControlUint as scUint,
    StateControlAddress as scAddress
} from "../utils/StateControl.sol";


contract LoanTreasurey is Ownable, ILoanTreasurey, ERC165 {
    address private debtTokenAddress;

    /**
     * @dev Emitted when deb token(s) are distributed.
     */
    event DebtTokenIssued(
        address indexed loanContract,
        address indexed debtTokenAddress,
        uint256 indexed debtTokenId,
        address tokenContractAddress
    );

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ILoanTreasurey).interfaceId || super.supportsInterface(interfaceId);
    }

    function makePayment(address _loanContractAddress) external payable {
        (bool _success, ) = _loanContractAddress.call{ value: msg.value }(
            abi.encodeWithSignature("makePayment()")
        );

        require(_success, "Payment failed.");
    }

    function withdrawFunds(address _loanContractAddress) external {
        ILoanContract(_loanContractAddress).withdrawFunds(_msgSender());
    }

    function getBalance(address _loanContractAddress)
        external
        view
        returns (uint256)
    {
        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        return _loanContract.getBalance();
    }

    function updateBalance(address _loanContractAddress) external onlyOwner() {
        ILoanContract(_loanContractAddress).updateBalance();
    }

    /**
     * @dev Assess loan maturity. If loan is defaulted, this function will initiate the
     * LoanContract default function.
     * 
     * Requirements:
     * 
     * - The loan must be in an active state as defined in 
     * {LibContractMaster.LibContractAssess.checkActiveState_()}
     */
    function assessMaturity(address _loanContractAddress) external onlyOwner() {
        States.LoanState _assessedState = Treasurey.assessMaturity_(_loanContractAddress);

        if (_assessedState == States.LoanState.DEFAULT) {
            Treasurey.initDefault_(_loanContractAddress);
        }
    }

    /**
     * @dev Set the AnzaDebtToken address.
     * 
     * Requirements:
     * 
     * - Only the treasurer can call this function.
     */
    function setDebtTokenAddress(address _debtTokenAddress) external onlyOwner() {
        debtTokenAddress = _debtTokenAddress;
    }
    
    function issueDebtToken(address _loanContractAddress, string memory _debtURI) external {
        require(debtTokenAddress != address(0), "Debt token not set");
        States.checkActiveState_(_loanContractAddress);
        _checkRole(Globals._PARTICIPANT_ROLE_, _loanContractAddress);

        ILoanContract _loanContract = ILoanContract(_loanContractAddress);
        IAnzaDebtToken _anzaDebtToken = IAnzaDebtToken(debtTokenAddress);
        
        (,,,,,,scUint.Property memory _balance,) = _loanContract.loanProperties();
        (, uint256 _debtId,) = _loanContract.loanGlobals();

        _anzaDebtToken.mintDebt(_loanContractAddress, _debtId, _balance._value, _debtURI);

        emit DebtTokenIssued(
            address(this),
            debtTokenAddress,
            _debtId,
            _loanContractAddress
        );
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address _loanContractAddress) internal view {
        if (!ILoanContract(_loanContractAddress).hasRole(role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    fallback() external {}
}