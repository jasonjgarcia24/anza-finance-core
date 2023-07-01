// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";
import {Test, Vm} from "forge-std/Test.sol";

contract PiggyBankEvents {
    event Deposited(address indexed from, address indexed to, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
}

contract PiggyBank is PiggyBankEvents {
    uint256 public totalBalance;
    mapping(address account => uint256) public balances;

    function deposit(address _account) external payable {
        require(msg.value != 0, "invalid deposit");

        // Increment record
        totalBalance += msg.value;
        balances[_account] += msg.value;

        // Emit event
        emit Deposited(msg.sender, _account, msg.value);
    }

    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "balance too low");

        // Decrement record
        totalBalance -= _amount;
        balances[msg.sender] -= _amount;

        payable(msg.sender).transfer(_amount);

        // Emit event
        emit Withdrawn(msg.sender, _amount);
    }
}

contract PiggyBankTest is Test, PiggyBankEvents {
    function testPiggyBank_Withdraw() public {
        // Create PiggyBank contract
        PiggyBank piggyBank = new PiggyBank();
        uint256 _amount = 1000;

        // Deposit
        vm.deal(msg.sender, _amount);
        vm.startPrank(msg.sender);
        (bool _success, ) = address(piggyBank).call{value: _amount}(
            abi.encodeWithSignature("deposit(address)", msg.sender)
        );
        assertTrue(_success, "deposited payment.");
        vm.stopPrank();

        // Set withdraw event expectations
        vm.expectEmit(true, false, false, true, address(piggyBank));
        emit Withdrawn(msg.sender, 1000);

        // Withdraw
        vm.startPrank(msg.sender);
        piggyBank.withdraw(_amount);
        vm.stopPrank();
    }

    function testPiggyBank_FAIL_Deposit() public {
        PiggyBank piggyBank = new PiggyBank();

        // Deposit
        vm.deal(msg.sender, 1000);
        vm.startPrank(msg.sender);

        // Set deposit event expectations
        vm.expectEmit(true, true, true, true, address(piggyBank));
        emit Deposited(msg.sender, address(piggyBank), 1000);
        (bool _success, ) = address(piggyBank).call{value: 1000}(
            abi.encodeWithSignature("deposit(address)", msg.sender)
        );
        assertTrue(_success, "deposited payment.");

        vm.stopPrank();

        // Withdraw
        vm.startPrank(msg.sender);

        // Set withdraw event expectations
        vm.expectEmit(true, true, true, true, address(piggyBank));
        emit Withdrawn(msg.sender, 1000);

        piggyBank.withdraw(1000);

        vm.stopPrank();
    }

    address internal constant RECEIVER =
        address(uint160(uint256(keccak256("piggy bank test receiver"))));

    function testPiggyBank_Deposit() public {
        PiggyBank piggyBank = new PiggyBank();
        uint256 _amount = 1000;

        // Start recording all emitted events
        vm.recordLogs();

        // Deposit
        vm.deal(msg.sender, _amount);
        vm.startPrank(msg.sender);
        (bool _success, ) = address(piggyBank).call{value: _amount}(
            abi.encodeWithSignature("deposit(address)", RECEIVER)
        );
        vm.stopPrank();

        assertTrue(_success, "deposited payment.");

        // Consume the recorded logs
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Check logs
        bytes32 deposited_event_signature = keccak256(
            "Deposited(address,address,uint256)"
        );

        for (uint256 i; i < entries.length; i++) {
            if (entries[i].topics[0] == deposited_event_signature) {
                assertEq(
                    address(uint160(uint256((entries[i].topics[1])))),
                    msg.sender,
                    "emitted sender mismatch."
                );
                assertEq(
                    address(uint160(uint256((entries[i].topics[2])))),
                    RECEIVER,
                    "emitted receiver mismatch."
                );
                assertEq(
                    abi.decode(entries[i].data, (uint256)),
                    _amount,
                    "emitted amount mismatch."
                );
                assertEq(
                    entries[i].emitter,
                    address(piggyBank),
                    "emitter contract mismatch."
                );

                break;
            }

            if (i == entries.length - 1)
                fail("emitted deposited event not found.");
        }
    }
}
