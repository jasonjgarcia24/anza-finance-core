// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "./interfaces/ILoanCollateralVault.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {LibOfficerRoles as Roles} from "./libraries/LibLoanContract.sol";

contract LoanCollateralVault is
    AccessControl,
    ERC721Holder,
    ILoanCollateralVault
{
    uint256 private __totalCollateral;
    Collateral[] private __collaterals;

    constructor(address _admin) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._LOAN_CONTRACT_, Roles._ADMIN_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, _admin);
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
    ) external onlyRole(Roles._TREASURER_) {
        __totalCollateral -= 1;

        Collateral storage _collateral = __collaterals[_debtId];
        IERC721 _collateralContract = IERC721(_collateral.collateralAddress);

        _collateralContract.approve(msg.sender, _collateral.collateralId);

        _collateralContract.safeTransferFrom(
            msg.sender,
            _to,
            _collateral.collateralId,
            ""
        );

        emit CollateralWithdrawn(
            _to,
            _collateral.collateralAddress,
            _collateral.collateralId
        );
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _collateralId,
        bytes memory _data
    ) public override returns (bytes4) {
        _checkRole(Roles._LOAN_CONTRACT_, _operator);

        __totalCollateral += 1;

        address _collateralAddress = address(bytes20(_data));

        __collaterals.push(Collateral(_collateralAddress, _collateralId));

        emit CollateralDeposited(_from, _collateralAddress, _collateralId);

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
