// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "./interfaces/ILoanCollateralVault.sol";
import "./interfaces/ILoanContract.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {LibOfficerRoles as Roles} from "./libraries/LibLoanContract.sol";

contract LoanCollateralVault is
    ILoanCollateralVault,
    AccessControl,
    ERC721Holder
{
    uint256 private __totalCollateral;
    address private __loanContract;
    mapping(uint256 => Collateral) private __collaterals;

    constructor() {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._LOAN_CONTRACT_, Roles._ADMIN_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, msg.sender);
    }

    function loanContract() external view returns (address) {
        return __loanContract;
    }

    function setLoanContract(
        address _loanContract
    ) external onlyRole(Roles._ADMIN_) {
        __loanContract = _loanContract;
    }

    function totalCollateral() external view returns (uint256) {
        return __totalCollateral;
    }

    function getCollateralAt(
        uint256 _debtId
    ) external view returns (Collateral memory) {
        return __collaterals[_debtId];
    }

    function withdraw(
        address _to,
        uint256 _debtId
    ) external onlyRole(Roles._TREASURER_) returns (bool) {
        Collateral storage _collateral = __collaterals[_debtId];
        __totalCollateral -= 1;

        IERC721(_collateral.collateralAddress).safeTransferFrom(
            address(this),
            _to,
            _collateral.collateralId,
            ""
        );

        emit WithdrawnCollateral(
            _to,
            _collateral.collateralAddress,
            _collateral.collateralId
        );

        return true;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _collateralId,
        bytes memory _data
    ) public override returns (bytes4) {
        address _collateralAddress = msg.sender;
        uint256 _debtId = uint256(bytes32(_data));

        // Validate debt ID
        _checkDebtId(_collateralAddress, _collateralId, _debtId);

        // Add collateral to inventory
        __totalCollateral += 1;
        __collaterals[_debtId] = Collateral(_collateralAddress, _collateralId);

        emit DepositedCollateral(_from, _collateralAddress, _collateralId);

        // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        return 0x150b7a02;
    }

    /*
     * This check ensures two things:
     *   1. The collateral token is associated with the `_debtId`
     *      within the loan contract
     *   2. No collateral token has not been previously deposited
     *      for this `_debtId`
     */
    function _checkDebtId(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) internal {
        if (
            ILoanContract(__loanContract).debtIds(
                _collateralAddress,
                _collateralId,
                0
            ) !=
            _debtId ||
            __collaterals[_debtId].collateralAddress != address(0)
        ) revert IllegalDebtId();
    }
}
