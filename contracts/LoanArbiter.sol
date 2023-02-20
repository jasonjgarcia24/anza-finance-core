// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {LibOfficerRoles as Roles} from "./libraries/LibLoanContract.sol";
import "hardhat/console.sol";

contract LoanArbiter is AccessControl, IERC721Receiver {
    struct Collateral {
        bytes collateralAddress;
        uint256 collateralId;
        uint256 debtId;
    }

    uint256 private _totalCollateral;
    Collateral[] private _collaterals;

    constructor(
        address _admin,
        address _treasurer,
        address _collector
    ) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._LOAN_CONTRACT_, Roles._LOAN_CONTRACT_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);
        _setRoleAdmin(Roles._COLLECTOR_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, _admin);
        _grantRole(Roles._TREASURER_, _treasurer);
        _grantRole(Roles._COLLECTOR_, _collector);
    }

    function withdraw(
        address _to,
        address _collateralAddress,
        uint256 _collateralId
    ) external onlyRole(Roles._LOAN_CONTRACT_) {
        _totalCollateral -= 1;

        IERC721(_collateralAddress).safeTransferFrom(
            msg.sender,
            _to,
            _collateralId,
            ""
        );
    }

    function totalCollateral() external view returns (uint256) {
        return _totalCollateral;
    }

    function getCollateralAt(uint256 _debtId)
        external
        view
        returns (Collateral memory)
    {
        return _collaterals[_debtId];
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
        address,
        uint256 _collateralId,
        bytes calldata _collateralAddress
    ) external returns (bytes4) {
        _totalCollateral += 1;

        _collaterals.push(
            Collateral(_collateralAddress, _collateralId, _totalCollateral)
        );

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
