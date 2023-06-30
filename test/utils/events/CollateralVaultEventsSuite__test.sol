// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {Bytes32Utils} from "@test-utils/test-utils/Bytes32Utils.sol";

// 0x8454282b08531cdbd2142ac846ae921ccea242b7bc97cc8fe966bf8d57f5efd9
bytes32 constant DEPOSITED_COLLATERAL_EVENT_SIG = keccak256(
    "DepositedCollateral(address,address,uint256)"
);

// 0x39232a7eed2ad0ea7afab6b1edffa01bbd4a635bf106ac38ec5261d8d691f4a0
bytes32 constant WITHDRAWN_COLLATERAL_EVENT_SIG = keccak256(
    "WithdrawnCollateral(address,address,uint256)"
);

interface ICollateralVaultEvents {
    event DepositedCollateral(
        address indexed from,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    event WithdrawnCollateral(
        address indexed to,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );
}

library CollateralVaultEventsParse {
    using Bytes32Utils for bytes32;

    function parseDepositedCollateral(
        Vm.Log memory _entry
    )
        public
        pure
        returns (
            address _from,
            address _collateralAddress,
            uint256 _collateralId
        )
    {
        require(
            _entry.topics[0] == DEPOSITED_COLLATERAL_EVENT_SIG,
            "CollateralVaultEventsParse: invalid DepositedCollateral topic"
        );

        _from = _entry.topics[1].addressFromLast20Bytes();
        _collateralAddress = _entry.topics[2].addressFromLast20Bytes();
        _collateralId = uint256(_entry.topics[3]);
    }

    function parseWithdrawnCollateral(
        Vm.Log memory _entry
    )
        public
        pure
        returns (address _to, address _collateralAddress, uint256 _collateralId)
    {
        require(
            _entry.topics[0] == WITHDRAWN_COLLATERAL_EVENT_SIG,
            "CollateralVaultEventsParse: invalid WithdrawnCollateral topic"
        );

        _to = _entry.topics[1].addressFromLast20Bytes();
        _collateralAddress = _entry.topics[2].addressFromLast20Bytes();
        _collateralId = uint256(_entry.topics[3]);
    }
}

abstract contract CollateralVaultEventsSuite is Test {
    struct DepositedCollateralFields {
        address from;
        address collateralAddress;
        uint256 collateralId;
    }

    struct WithdrawnCollateralFields {
        address to;
        address collateralAddress;
        uint256 collateralId;
    }

    function _testDepositedCollateral(
        Vm.Log memory _entry,
        DepositedCollateralFields memory _expectedValues
    ) internal {
        (
            address _from,
            address _collateralAddress,
            uint256 _collateralId
        ) = CollateralVaultEventsParse.parseDepositedCollateral(_entry);

        assertEq(
            _from,
            _expectedValues.from,
            "0 :: _testDepositedCollateral :: emitted event from mismatch."
        );
        assertEq(
            _collateralAddress,
            _expectedValues.collateralAddress,
            "1 :: _testDepositedCollateral :: emitted event collateralAddress mismatch."
        );
        assertEq(
            _collateralId,
            _expectedValues.collateralId,
            "2 :: _testDepositedCollateral :: emitted event collateralId mismatch."
        );
    }

    function _testWithdrawnCollateral(
        Vm.Log memory _entry,
        WithdrawnCollateralFields memory _expectedValues
    ) internal {
        (
            address _to,
            address _collateralAddress,
            uint256 _collateralId
        ) = CollateralVaultEventsParse.parseWithdrawnCollateral(_entry);

        assertEq(
            _to,
            _expectedValues.to,
            "0 :: _testWithdrawnCollateral :: emitted event to mismatch."
        );
        assertEq(
            _collateralAddress,
            _expectedValues.collateralAddress,
            "1 :: _testWithdrawnCollateral :: emitted event collateralAddress mismatch."
        );
        assertEq(
            _collateralId,
            _expectedValues.collateralId,
            "2 :: _testWithdrawnCollateral :: emitted event collateralId mismatch."
        );
    }
}
