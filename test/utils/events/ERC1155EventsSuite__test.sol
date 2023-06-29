// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {Bytes32Utils} from "@test-utils/test-utils/Bytes32Utils.sol";

// 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
bytes32 constant TRANSFER_SINGLE_EVENT_SIG = keccak256(
    "TransferSingle(address,address,address,uint256,uint256)"
);

// 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
bytes32 constant TRANSFER_BATCH_EVENT_SIG = keccak256(
    "TransferBatch(address,address,address,uint256[],uint256[])"
);

// 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b
bytes32 constant URI_EVENT_SIG = keccak256("URI(string,uint256)");

/// @title ERC-1155 Multi Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155Events {
    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_id` argument MUST be the token type being transferred.
    /// - The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_ids` argument MUST be the list of tokens being transferred.
    /// - The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    // /// @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    // event ApprovalForAll(
    //     address indexed _owner,
    //     address indexed _operator,
    //     bool _approved
    // );

    /// @dev MUST emit when the URI is updated for a token ID. URIs are defined in RFC 3986.
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    event URI(string _value, uint256 indexed _id);
}

library ERC1155EventsParse {
    using Bytes32Utils for bytes32;

    function parseTransferSingle(
        Vm.Log memory _entry
    )
        public
        pure
        returns (
            address _operator,
            address _from,
            address _to,
            uint256 _id,
            uint256 _value
        )
    {
        require(
            _entry.topics[0] == TRANSFER_SINGLE_EVENT_SIG,
            "ERC1155EventsParse: invalid TransferSingle topic"
        );

        _operator = _entry.topics[1].addressFromLast20Bytes();
        _from = _entry.topics[2].addressFromLast20Bytes();
        _to = _entry.topics[3].addressFromLast20Bytes();

        (_id, _value) = abi.decode(_entry.data, (uint256, uint256));
    }

    function parseTransferBatch(
        Vm.Log memory _entry
    )
        public
        pure
        returns (
            address _operator,
            address _from,
            address _to,
            uint256[] memory _ids,
            uint256[] memory _values
        )
    {
        require(
            _entry.topics[0] == TRANSFER_BATCH_EVENT_SIG,
            "ERC1155EventsParse: invalid TransferBatch topic"
        );

        _operator = _entry.topics[1].addressFromLast20Bytes();
        _from = _entry.topics[2].addressFromLast20Bytes();
        _to = _entry.topics[3].addressFromLast20Bytes();

        (_ids, _values) = abi.decode(_entry.data, (uint256[], uint256[]));
    }

    function parseURI(
        Vm.Log memory _entry
    ) public pure returns (string memory _value, uint256 _id) {
        require(
            _entry.topics[0] == URI_EVENT_SIG,
            "ERC1155EventsParse: invalid URI topic"
        );

        _value = abi.decode(_entry.data, (string));
        _id = uint256(_entry.topics[1]);
    }
}

abstract contract ERC1155EventsSuite is Test {
    struct TransferSingleFields {
        address operator;
        address from;
        address to;
        uint256 id;
        uint256 value;
    }

    struct TransferBatchFields {
        address operator;
        address from;
        address to;
        uint256[] ids;
        uint256[] values;
    }

    struct URIFields {
        string value;
        uint256 id;
    }

    function _testTransferSingle(
        Vm.Log memory _entry,
        TransferSingleFields memory _expectedValues
    ) internal {
        (
            address _operator,
            address _from,
            address _to,
            uint256 _id,
            uint256 _value
        ) = ERC1155EventsParse.parseTransferSingle(_entry);

        assertEq(
            _operator,
            _expectedValues.operator,
            "0 :: _testTransferSingle :: emitted event operator mismatch."
        );
        assertEq(
            _from,
            _expectedValues.from,
            "1 :: _testTransferSingle :: emitted event from mismatch."
        );
        assertEq(
            _to,
            _expectedValues.to,
            "2 :: _testTransferSingle :: emitted event to mismatch."
        );
        assertEq(
            _id,
            _expectedValues.id,
            "3 :: _testTransferSingle :: emitted event id mismatch."
        );
        assertEq(
            _value,
            _expectedValues.value,
            "4 :: _testTransferSingle :: emitted event value mismatch."
        );
    }

    function _testTransferBatch(
        Vm.Log memory _entry,
        TransferBatchFields memory _expectedValues
    ) internal {
        (
            address _operator,
            address _from,
            address _to,
            uint256[] memory _ids,
            uint256[] memory _values
        ) = ERC1155EventsParse.parseTransferBatch(_entry);

        assertEq(
            _operator,
            _expectedValues.operator,
            "0 :: _testTransferBatch :: emitted event operator mismatch."
        );
        assertEq(
            _from,
            _expectedValues.from,
            "1 :: _testTransferBatch :: emitted event from mismatch."
        );
        assertEq(
            _to,
            _expectedValues.to,
            "2 :: _testTransferBatch :: emitted event to mismatch."
        );
        assertEq(
            _ids,
            _expectedValues.ids,
            "3 :: _testTransferBatch :: emitted event ids mismatch."
        );
        assertEq(
            _values,
            _expectedValues.values,
            "4 :: _testTransferBatch :: emitted event values mismatch."
        );
    }

    function _testURI(
        Vm.Log memory _entry,
        URIFields memory _expectedValues
    ) internal {
        (string memory _value, uint256 _id) = ERC1155EventsParse.parseURI(
            _entry
        );

        assertEq(
            _value,
            _expectedValues.value,
            "0 :: _testURI :: emitted event value mismatch."
        );
        assertEq(
            _id,
            _expectedValues.id,
            "1 :: _testURI :: emitted event id mismatch."
        );
    }
}
