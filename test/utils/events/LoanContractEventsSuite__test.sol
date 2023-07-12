// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {Bytes32Utils} from "@test-utils/test-utils/Bytes32Utils.sol";

// 0x017b4ae07fd1f6af130b3591d7030755a4d2b1151496f6cd4ea91a190fbd331a
bytes32 constant CONTRACT_INTIALIZED_EVENT_SIG = keccak256(
    "ContractInitialized(address,uint256,uint256,uint256)"
);

// 0x1ac9410f2d38165d10157abc9269c78ebceb015b7d432a29c6ffcea7b795a380
bytes32 constant PROPOSAL_REVOKED_EVENT_SIG = keccak256(
    "ProposalRevoked(address,uint256,uint256,bytes32)"
);

interface ILoanContractEvents {
    event ContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId,
        uint256 activeLoanIndex
    );

    event ProposalRevoked(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed collateralNonce,
        bytes32 contractTerms
    );
}

library LoanContractEventsParse {
    using Bytes32Utils for bytes32;

    function parseContractInitialized(
        Vm.Log memory _entry
    )
        public
        pure
        returns (
            address _collateralAddress,
            uint256 _collateralId,
            uint256 _debtId,
            uint256 _activeLoanIndex
        )
    {
        require(
            _entry.topics[0] == CONTRACT_INTIALIZED_EVENT_SIG,
            "LoanContractEventsParse: invalid ContractInitialized topic"
        );

        _collateralAddress = _entry.topics[1].addressFromLast20Bytes();
        _collateralId = uint256(_entry.topics[2]);
        _debtId = uint256(_entry.topics[3]);
        _activeLoanIndex = abi.decode(_entry.data, (uint256));
    }

    function parseProposalRevoked(
        Vm.Log memory _entry
    )
        public
        pure
        returns (
            address _collateralAddress,
            uint256 _collateralId,
            uint256 _collateralNonce,
            bytes32 _contractTerms
        )
    {
        require(
            _entry.topics[0] == PROPOSAL_REVOKED_EVENT_SIG,
            "LoanContractEventsParse: invalid ProposalRevoked topic"
        );

        _collateralAddress = _entry.topics[1].addressFromLast20Bytes();
        _collateralId = uint256(_entry.topics[2]);
        _collateralNonce = uint256(_entry.topics[3]);
        _contractTerms = abi.decode(_entry.data, (bytes32));
    }
}

abstract contract LoanContractEventsSuite is Test {
    struct ContractInitializedFields {
        address collateralAddress;
        uint256 collateralId;
        uint256 debtId;
        uint256 activeLoanIndex;
    }

    struct ProposalRevokedFields {
        address collateralAddress;
        uint256 collateralId;
        uint256 collateralNonce;
        bytes32 contractTerms;
    }

    function _testContractInitialized(
        Vm.Log memory _entry,
        ContractInitializedFields memory _expectedValues
    ) internal {
        (
            address _collateralAddress,
            uint256 _collateralId,
            uint256 _debtId,
            uint256 _activeLoanIndex
        ) = LoanContractEventsParse.parseContractInitialized(_entry);

        assertEq(
            _collateralAddress,
            _expectedValues.collateralAddress,
            "0 :: _testContractInitialized :: emitted event collateralAddress mismatch."
        );
        assertEq(
            _collateralId,
            _expectedValues.collateralId,
            "1 :: _testContractInitialized :: emitted event collateralId mismatch."
        );
        assertEq(
            _debtId,
            _expectedValues.debtId,
            "2 :: _testContractInitialized :: emitted event debtId mismatch."
        );
        assertEq(
            _activeLoanIndex,
            _expectedValues.activeLoanIndex,
            "3 :: _testContractInitialized :: emitted event activeLoanIndex mismatch."
        );
    }

    function _testProposalRevoked(
        Vm.Log memory _entry,
        ProposalRevokedFields memory _expectedValues
    ) internal {
        (
            address _collateralAddress,
            uint256 _collateralId,
            uint256 _collateralNonce,
            bytes32 _contractTerms
        ) = LoanContractEventsParse.parseProposalRevoked(_entry);

        assertEq(
            _collateralAddress,
            _expectedValues.collateralAddress,
            "0 :: _testProposalRevoked :: emitted event collateralAddress mismatch."
        );
        assertEq(
            _collateralId,
            _expectedValues.collateralId,
            "1 :: _testProposalRevoked :: emitted event collateralId mismatch."
        );
        assertEq(
            _collateralNonce,
            _expectedValues.collateralNonce,
            "2 :: _testProposalRevoked :: emitted event collateralNonce mismatch."
        );
        assertEq(
            _contractTerms,
            _expectedValues.contractTerms,
            "3 :: _testProposalRevoked :: emitted event contractTerms mismatch."
        );
    }
}
