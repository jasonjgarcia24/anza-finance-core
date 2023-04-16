// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "./domain/LoanContractRoles.sol";
import "./domain/LoanContractStates.sol";

import "./interfaces/ICollateralVault.sol";
import "./access/VaultAccessController.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CollateralVault is
    ICollateralVault,
    VaultAccessController,
    ERC721Holder
{
    uint256 public totalCollateral;
    mapping(uint256 => Collateral) private __collaterals;

    constructor(
        address _anzaTokenAddress
    ) VaultAccessController(_anzaTokenAddress) {}

    modifier onlyDepositAllowed(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) {
        if (!depositAllowed(_collateralAddress, _collateralId, _debtId))
            revert UnallowedDeposit();
        _;
    }

    modifier onlyWithdrawalAllowed(address _to, uint256 _debtId) {
        if (!withdrawalAllowed(_to, _debtId)) revert UnallowedWithdrawal();
        _;
    }

    function getCollateral(
        uint256 _debtId
    ) external view returns (Collateral memory) {
        return __collaterals[_debtId];
    }

    function setCollateral(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) external onlyRole(_LOAN_CONTRACT_) {
        _deposit(false, msg.sender, _collateralAddress, _collateralId, _debtId);
    }

    /**
     * @dev Returns whether a token is allowed to be deposited as collateral or
     * stored as a reference to collateral.
     * @param _collateralAddress The collateral token's contract address.
     * @param _collateralId The collateral token's ID.
     * @param _debtId The debt ID associated with the collateral.
     *
     * This checks two things:
     *   1. The collateral token is associated with the `_debtId`
     *      within the loan contract.
     *   2. No collateral token has not been previously deposited
     *      for this `_debtId`.
     */
    function depositAllowed(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) public returns (bool) {
        return
            ILoanContract(_loanContract).debtIds(
                _collateralAddress,
                _collateralId,
                ILoanCodec(_loanContract).activeLoanCount(_debtId)
            ) ==
            _debtId &&
            __collaterals[_debtId].collateralAddress == address(0);
    }

    /**
     * @dev Returns whether an address is allowed to withdraw their collateral.
     * @param _to The destination address of the collateral.
     * @param _debtId The debt ID mapped to the collateral.
     *
     * This checks three things:
     *   1. The debt ID is a vault containing the collateral.
     *   2. The loan state is paid in full.
     *   3. The recipient is the documented borrower.
     */
    function withdrawalAllowed(
        address _to,
        uint256 _debtId
    ) public view returns (bool) {
        return
            __collaterals[_debtId].vault &&
            ILoanCodec(_loanContract).loanState(_debtId) == _PAID_STATE_ &&
            IAnzaToken(anzaToken).checkBorrowerOf(_to, _debtId);
    }

    function withdraw(
        address _to,
        uint256 _debtId
    )
        external
        onlyRole(_TREASURER_)
        onlyWithdrawalAllowed(_to, _debtId)
        returns (bool)
    {
        Collateral storage _collateral = __collaterals[_debtId];
        totalCollateral -= 1;

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
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via
     * {IERC721-safeTransferFrom} by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient,
     * the transfer will be reverted.
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _collateralId,
        bytes memory _data
    ) public override returns (bytes4) {
        uint256 _debtId = uint256(bytes32(_data));

        _deposit(true, _from, msg.sender, _collateralId, _debtId);

        // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        return 0x150b7a02;
    }

    function _deposit(
        bool _vault,
        address _from,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) internal onlyDepositAllowed(_collateralAddress, _collateralId, _debtId) {
        // Add collateral to inventory
        totalCollateral += 1;
        __collaterals[_debtId] = Collateral(
            _collateralAddress,
            _collateralId,
            _vault
        );

        if (_vault)
            emit DepositedCollateral(_from, _collateralAddress, _collateralId);
    }
}
