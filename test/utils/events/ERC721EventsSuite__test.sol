// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {Bytes32Utils} from "@test-utils/test-utils/Bytes32Utils.sol";

// 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
bytes32 constant TRANSFER_EVENT_SIG = keccak256(
    "Transfer(address,address,uint256)"
);

// 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
bytes32 constant APPROVAL_EVENT_SIG = keccak256(
    "Approval(address,address,uint256)"
);

// 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
bytes32 constant APPROVAL_FOR_ALL_EVENT_SIG = keccak256(
    "ApprovalForAll(address,address,bool)"
);

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721Events {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    /// This event emits when NFTs are created (`from` == 0) and destroyed
    /// (`to` == 0). Exception: during contract creation, any number of NFTs
    /// may be created and assigned without emitting Transfer. At the time of
    /// any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    /// reaffirmed. The zero address indicates there is no approved address.
    /// When a Transfer event emits, this also indicates that the approved
    /// address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    /// The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}

library ERC721EventsParse {
    using Bytes32Utils for bytes32;

    function parseTransfer(
        Vm.Log memory _entry
    ) public pure returns (address _from, address _to, uint256 _tokenId) {
        require(
            _entry.topics[0] == TRANSFER_EVENT_SIG,
            "ERC721EventsParse: invalid Transfer topic"
        );

        _from = _entry.topics[1].addressFromLast20Bytes();
        _to = _entry.topics[2].addressFromLast20Bytes();
        _tokenId = uint256(_entry.topics[3]);
    }

    function parseApproval(
        Vm.Log memory _entry
    )
        public
        pure
        returns (address _owner, address _approved, uint256 _tokenId)
    {
        require(
            _entry.topics[0] == APPROVAL_EVENT_SIG,
            "ERC721EventsParse: invalid Approval topic"
        );

        _owner = _entry.topics[1].addressFromLast20Bytes();
        _approved = _entry.topics[2].addressFromLast20Bytes();
        _tokenId = uint256(_entry.topics[3]);
    }

    function parseApprovalForAll(
        Vm.Log memory _entry
    ) public pure returns (address _owner, address _operator, bool _approved) {
        require(
            _entry.topics[0] == APPROVAL_FOR_ALL_EVENT_SIG,
            "ERC721EventsParse: invalid ApprovalForAll topic"
        );

        _owner = _entry.topics[1].addressFromLast20Bytes();
        _operator = _entry.topics[2].addressFromLast20Bytes();

        (_approved) = abi.decode(_entry.data, (bool));
    }
}

abstract contract ERC721EventsSuite is Test {
    struct TransferFields {
        address from;
        address to;
        uint256 tokenId;
    }

    struct ApprovalFields {
        address owner;
        address approved;
        uint256 tokenId;
    }

    struct ApprovalForAll {
        address owner;
        address operator;
        bool approved;
    }

    function _testTransfer(
        Vm.Log memory _entry,
        TransferFields memory _expectedValues
    ) internal {
        (address _from, address _to, uint256 _tokenId) = ERC721EventsParse
            .parseTransfer(_entry);

        assertEq(
            _from,
            _expectedValues.from,
            "0 :: _testTransfer :: emitted event from mismatch."
        );
        assertEq(
            _to,
            _expectedValues.to,
            "1 :: _testTransfer :: emitted event to mismatch."
        );
        assertEq(
            _tokenId,
            _expectedValues.tokenId,
            "2 :: _testTransfer :: emitted event tokenId mismatch."
        );
    }

    function _testApproval(
        Vm.Log memory _entry,
        ApprovalFields memory _expectedValues
    ) internal {
        (
            address _owner,
            address _approved,
            uint256 _tokenId
        ) = ERC721EventsParse.parseApproval(_entry);

        assertEq(
            _owner,
            _expectedValues.owner,
            "0 :: _testApproval :: emitted event owner mismatch."
        );
        assertEq(
            _approved,
            _expectedValues.approved,
            "1 :: _testApproval :: emitted event approved mismatch."
        );
        assertEq(
            _tokenId,
            _expectedValues.tokenId,
            "2 :: _testApproval :: emitted event tokenId mismatch."
        );
    }

    function _testApprovalForAll(
        Vm.Log memory _entry,
        ApprovalForAll memory _expectedValues
    ) internal {
        (address _owner, address _operator, bool _approved) = ERC721EventsParse
            .parseApprovalForAll(_entry);

        assertEq(
            _owner,
            _expectedValues.owner,
            "0 :: _testApprovalForAll :: emitted event owner mismatch."
        );
        assertEq(
            _operator,
            _expectedValues.operator,
            "1 :: _testApprovalForAll :: emitted event operator mismatch."
        );
        assertEq(
            _approved,
            _expectedValues.approved,
            "2 :: _testApprovalForAll :: emitted event approved mismatch."
        );
    }
}
