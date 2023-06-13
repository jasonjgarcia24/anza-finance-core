// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAnzaBaseMarketParticipant} from "@market-interfaces/IAnzaBaseMarketParticipant.sol";
import {NonceLocker} from "../utils/NonceLocker.sol";

abstract contract AnzaBaseMarketParticipant is IAnzaBaseMarketParticipant {
    /* ------------------------------------------------ *
     *                    Databases                     *
     * ------------------------------------------------ */
    mapping(address beneficiary => uint256) internal _proceeds;
    mapping(bytes32 signatureHash => bool) internal _canceledListings;

    NonceLocker.Nonce[] internal _nonces;

    /**
     * Returns the next listing nonce.
     *
     * The listing nonce is used to verify the listing when a buyer attempts to
     * purchase the debt {see LoanNotary:LoanNotary-__structHash}.
     *
     * @notice The listing nonce is incremented each time a listing is published,
     * therefore the listing nonce provided by this function is the next listing
     * available and can be locked out by publishing a debt listing.
     *
     * @return _nonce The next debt listing nonce.
     */
    function nonce() external view returns (uint256) {
        return _nonces.length;
    }
}
