// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_} from "@lending-constants/LoanContractRoles.sol";
import "@markets-constants/AnzaDebtMarketRoles.sol";
import "@markets-constants/AnzaDebtStorefrontSelectors.sol";
import {StdAnzaMarketErrors} from "@custom-errors/StdAnzaMarketErrors.sol";

import {IAnzaDebtMarket} from "@markets-interfaces/IAnzaDebtMarket.sol";
import {AnzaBaseMarketParticipant, NonceLocker} from "@markets-databases/AnzaBaseMarketParticipant.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract AnzaDebtMarket is
    IAnzaDebtMarket,
    AnzaBaseMarketParticipant,
    AccessControl
{
    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_DEBT_MARKET_, _ADMIN_);
        _setRoleAdmin(_DEBT_STOREFRONT_, _ADMIN_);
        _setRoleAdmin(_REFINANCE_STOREFRONT_, _ADMIN_);
        _setRoleAdmin(_CONSOLIDATION_STOREFRONT_, _ADMIN_);
        _setRoleAdmin(_SPONSORSHIP_STOREFRONT_, _ADMIN_);
        _setRoleAdmin(_OTHER_APPROVED_STOREFRONT_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);

        // Use up _nonce 0.
        _nonces.push(
            NonceLocker.ruin(address(this), uint8(ListingType.UNDEFINED))
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IAnzaDebtMarket).interfaceId ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _validateStorefrontRegistration(
        bytes4 _storefrontSelector,
        address _storefrontAddress
    ) internal view {
        // Approved debt storefront
        if (
            _storefrontSelector == _BUY_DEBT_UNPUBLISHED_ ||
            _storefrontSelector == _BUY_DEBT_PUBLISHED_
        ) {
            _checkRole(_DEBT_STOREFRONT_, _storefrontAddress);
        }
        // Approved refinance storefront
        else if (
            _storefrontSelector == _REFINANCE_DEBT_UNPUBLISHED_ ||
            _storefrontSelector == _REFINANCE_DEBT_PUBLISHED_
        ) {
            _checkRole(_REFINANCE_STOREFRONT_, _storefrontAddress);
        }
        // Approved sponsorship storefront
        else if (
            _storefrontSelector == _SPONSOR_DEBT_UNPUBLISHED_ ||
            _storefrontSelector == _SPONSOR_DEBT_PUBLISHED_
        ) {
            _checkRole(_SPONSORSHIP_STOREFRONT_, _storefrontAddress);
        }
        // Unapproved storefront
        else if (!hasRole(_OTHER_APPROVED_STOREFRONT_, _storefrontAddress)) {
            revert StdAnzaMarketErrors.InvalidStorefront();
        }
    }

    receive() external payable {
        revert StdAnzaMarketErrors.ReceiveCallIllegal();
    }

    /**
     * Anza Marketplace router to Anza Storefront implementations.
     *
     * This function is the entry point for all Anza Storefronts implementations.
     * Its modular design allows for the addition of community driven storefronts.
     * All calls to Anza Storefronts must be made through this function. By
     * performing a delegatecall to the storefront implementations, the Loan
     * Treasurey validates that all calls are through the Anza Marketplace.
     *
     * @dev The calldata passed to this function must be constructed as follows:
     *  abi.encodePacked(
     *      address(<Anza Storefront Contract>),
     *      abi.encodeWithSignature(
     *          <Anza Storefront Function Signature>,
     *          <Anza Storefront Function Arguments>
     *      )
     *  )
     *
     * @notice Only approved, registered Anza Storefronts can be exercised through
     * this process. See {_validateStorefrontRegistration} for the Storefront
     * validation process.
     *
     * @notice All Anza Storefronts must inherit and implement the IAnzaStorefront
     * interface and AnzaBaseMarketParticipant abstract contract. Note, there shall
     * not be any implementation of selfdestruct in any Anza Storefront contract.
     */
    fallback() external payable {
        // Pop contract address from calldata
        address _storefrontAddress = address(bytes20(msg.data));
        bytes memory _calldata = msg.data[20:msg.data.length];

        // Validate contract address is an approved storefront
        _validateStorefrontRegistration(bytes4(_calldata), _storefrontAddress);

        // Delegate call to storefront contract function
        (bool _success, bytes memory _data) = _storefrontAddress.delegatecall(
            abi.encodePacked(_calldata)
        );

        // Return error if one is present
        if (!_success) _revert(_data);
    }
}
