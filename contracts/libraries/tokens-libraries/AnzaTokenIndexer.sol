// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {_MAX_DEBT_ID_} from "@lending-constants/LoanContractNumbers.sol";
import {_INVALID_TOKEN_ID_SELECTOR_} from "@custom-errors/StdAnzaTokenErrors.sol";

library AnzaTokenIndexer {
    function tokenIdToDebtId(uint256 _tokenId) internal pure returns (uint256) {
        unchecked {
            return _tokenId / 2;
        }
    }

    function debtIdToBorrowerTokenId(
        uint256 _debtId
    ) internal pure returns (uint256 _tokenId) {
        assembly {
            if gt(_debtId, _MAX_DEBT_ID_) {
                mstore(0x20, _INVALID_TOKEN_ID_SELECTOR_)
                revert(0x20, 0x04)
            }

            _tokenId := add(mul(_debtId, 2), 1)
        }
    }

    function debtIdToLenderTokenId(
        uint256 _debtId
    ) internal pure returns (uint256 _tokenId) {
        assembly {
            if gt(_debtId, _MAX_DEBT_ID_) {
                mstore(0x20, _INVALID_TOKEN_ID_SELECTOR_)
                revert(0x20, 0x04)
            }

            _tokenId := mul(_debtId, 2)
        }
    }
}
