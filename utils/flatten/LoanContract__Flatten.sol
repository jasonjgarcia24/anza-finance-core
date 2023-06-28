// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

/* ------------------------------------------------ *
 *              Loan Contract Roles                 *
 * ------------------------------------------------ */
bytes32 constant _ADMIN_ = keccak256("_ADMIN_");
bytes32 constant _LOAN_CONTRACT_ = keccak256("_LOAN_CONTRACT_");
bytes32 constant _TREASURER_ = keccak256("_TREASURER_");
bytes32 constant _COLLATERAL_VAULT_ = keccak256("_COLLATERAL_VAULT_");
bytes32 constant _COLLECTOR_ = keccak256("_COLLECTOR_");

/* ------------------------------------------------ *
 *           Loan Term Error Selectors              *
 * ------------------------------------------------ */
// Example: bytes4(keccak256("_LOAN_STATE_ERROR_ID_"))
bytes4 constant _LOAN_STATE_ERROR_ID_ = 0xd06c1bad;
bytes4 constant _FIR_INTERVAL_ERROR_ID_ = 0xfcacf94a;
bytes4 constant _DURATION_ERROR_ID_ = 0x7cde7ce7;
bytes4 constant _PRINCIPAL_ERROR_ID_ = 0xbbc5f09e;
bytes4 constant _FIXED_INTEREST_RATE_ERROR_ID_ = 0xbfe4482e;
bytes4 constant _GRACE_PERIOD_ERROR_ID_ = 0x3bc4ef6a;
bytes4 constant _TIME_EXPIRY_ERROR_ID_ = 0xf0c15f40;
bytes4 constant _LENDER_ROYALTIES_ERROR_ID_ = 0xe1f90bbd;

/* ------------------------------------------------ *
 *        Loan Agreement Error Selectors            *
 * ------------------------------------------------ */
bytes4 constant _INVALID_COLLATERAL_SELECTOR_ = 0xd1ef4cea;

library StdLoanErrors {
    /* ------------------------------------------------ *
     *             Loan Agreement Errors                *
     * ------------------------------------------------ */
    error InvalidCollateral();
    error InvalidLoanState();
}

library StdMonetaryErrors {
    /* ------------------------------------------------ *
     *               Transaction Errors                 *
     * ------------------------------------------------ */
    error FailedFundsTransfer();
    error ExceededRefinanceLimit();
}

interface ILoanContract {
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

    event PaymentSubmitted(
        uint256 indexed debtId,
        address indexed borrower,
        address indexed lender,
        uint256 amount
    );

    event LoanBorrowerChanged(
        uint256 indexed debtId,
        address indexed newBorrower,
        address indexed oldBorrower
    );

    function initContract(
        address _collateralAddress,
        uint256 _collateralId,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) external payable;

    function initContract(
        uint256 _debtId,
        address _borrower,
        address _lender,
        bytes32 _contractTerms
    ) external payable;

    function initContract(
        uint256 _debtId,
        address _borrower,
        address _lender
    ) external payable;
}

interface ICollateralVault {
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

    struct Collateral {
        address collateralAddress;
        uint256 collateralId;
        uint256 activeLoanIndex;
    }

    function totalCollateral() external view returns (uint256);

    function getCollateral(
        uint256 _debtId
    ) external view returns (Collateral memory);

    function setCollateral(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId,
        uint256 _activeLoanIndex
    ) external;

    function depositAllowed(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) external returns (bool);

    function withdrawalAllowed(
        address _to,
        uint256 _debtId
    ) external view returns (bool);

    function withdraw(
        address _loanContractAddress,
        uint256 _debtId
    ) external returns (bool);
}

/* ------------------------------------------------ *
 *                  Loan States                     *
 * ------------------------------------------------ */
uint8 constant _UNDEFINED_STATE_ = 0;

// Active States
uint8 constant _ACTIVE_GRACE_STATE_ = 1;
uint8 constant _ACTIVE_STATE_ = 2;

// Inactive States
uint8 constant _DEFAULT_STATE_ = 3;
uint8 constant _COLLECTION_STATE_ = 4;
uint8 constant _AUCTION_STATE_ = 5;
uint8 constant _AWARDED_STATE_ = 6;

// Closed States
uint8 constant _PAID_PENDING_STATE_ = 7;
uint8 constant _CLOSE_STATE_ = 8;
uint8 constant _PAID_STATE_ = 9;
uint8 constant _CLOSE_DEFAULT_STATE_ = 10;

/* ------------------------------------------------ *
 *                 Contract Numbers                 *
 * ------------------------------------------------ */
uint256 constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;
uint256 constant _MAX_REFINANCES_ = 2008;
uint256 constant _MAX_DEBT_PRINCIPAL_ = type(uint256).max / _MAX_REFINANCES_;
uint256 constant _MAX_DEBT_ID_ = 57896044618658097711785492504343953926634992332820282019728792003956564819967; // (type(uint256).max / 2) - 1;

/* ------------------------------------------------ *
 *                Universal Numbers                 *
 * ------------------------------------------------ */
uint256 constant _UINT8_MAX_ = 255;
uint256 constant _UINT32_MAX_ = 4294967295;
uint256 constant _UINT64_MAX_ = 18446744073709551615;
uint256 constant _UINT256_MAX_ = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

uint256 constant _SECP256K1_CURVE_ORDER_ = 115792089237316195423570985008687907852837564279074904382605163141518161494337;

/* ------------------------------------------------ *
 *        Loan Codec Custom Error Selectors          *
 * ------------------------------------------------ */
bytes4 constant _INVALID_LOAN_PARAMETER_SELECTOR_ = 0x87eb23b2; // bytes4(keccak256("InvalidLoanParameter(bytes4)"))
bytes4 constant _INACTIVE_LOAN_STATE_SELECTOR_ = 0x90f54c85; // bytes4(keccak256("InactiveLoanState()"))
bytes4 constant _EXPIRED_LOAN_SELECTOR_ = 0xf342c922; // bytes4(keccak256("ExpriredLoan()"))

library StdCodecErrors {
    /* ------------------------------------------------ *
     *            Loan Codec Custom Errors              *
     * ------------------------------------------------ */
    error InvalidLoanParameter(bytes4);
    error InactiveLoanState();
    error ExpriredLoan();
}

interface ILoanManager {
    event LoanTermsRevoked(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );

    event LoanTermsReinstated(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );

    function maxRefinances() external pure returns (uint256);

    function updateLoanState(uint256 _debtId) external returns (uint256);

    function verifyLoanActive(uint256 _debtId) external view;

    function verifyLoanNotExpired(uint256 _debtId) external view;

    function checkLoanActive(uint256 _debtId) external view returns (bool);

    function checkLoanDefault(uint256 _debtId) external view returns (bool);

    function checkLoanExpired(uint256 _debtId) external view returns (bool);

    function checkLoanClosed(uint256 _debtId) external view returns (bool);
}

/* ------------------------------------------------ *
 *       Fixed Interest Rate (FIR) Intervals        *
 * ------------------------------------------------ */
//  Need to validate duration > FIR interval
uint8 constant _SECONDLY_ = 0;
uint8 constant _MINUTELY_ = 1;
uint8 constant _HOURLY_ = 2;
uint8 constant _DAILY_ = 3;
uint8 constant _WEEKLY_ = 4;
uint8 constant _2_WEEKLY_ = 5;
uint8 constant _4_WEEKLY_ = 6;
uint8 constant _6_WEEKLY_ = 7;
uint8 constant _8_WEEKLY_ = 8;
uint8 constant _MONTHLY_ = 9;
uint8 constant _2_MONTHLY_ = 10;
uint8 constant _3_MONTHLY_ = 11;
uint8 constant _4_MONTHLY_ = 12;
uint8 constant _6_MONTHLY_ = 13;
uint8 constant _360_DAILY_ = 14;
uint8 constant _ANNUALLY_ = 15;

/* ------------------------------------------------ *
 *               FIR Interval Multipliers           *
 * ------------------------------------------------ */
uint256 constant _SECONDLY_MULTIPLIER_ = 1;
uint256 constant _MINUTELY_MULTIPLIER_ = 60;
uint256 constant _HOURLY_MULTIPLIER_ = 60 * 60;
uint256 constant _DAILY_MULTIPLIER_ = 60 * 60 * 24;
uint256 constant _WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7;
uint256 constant _2_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 2;
uint256 constant _4_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 4;
uint256 constant _6_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 6;
uint256 constant _8_WEEKLY_MULTIPLIER_ = 60 * 60 * 24 * 7 * 8;
uint256 constant _360_DAILY_MULTIPLIER_ = 60 * 60 * 24 * 360;

/* ------------------------------------------------ *
 *           Packed Debt Term Mappings              *
 *-------------------------------------------*/
uint256 constant _LOAN_STATE_MASK_ =       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0;
uint256 constant _LOAN_STATE_MAP_ =        0x000000000000000000000000000000000000000000000000000000000000000F;
uint256 constant _FIR_INTERVAL_MASK_ =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0F;
uint256 constant _FIR_INTERVAL_MAP_ =      0x00000000000000000000000000000000000000000000000000000000000000F0;
uint256 constant _FIR_MASK_ =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FF;
uint256 constant _FIR_MAP_ =               0x000000000000000000000000000000000000000000000000000000000000FF00;
uint256 constant _LOAN_START_MASK_ =       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFF;
uint256 constant _LOAN_START_MAP_ =        0x00000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF0000;
uint256 constant _LOAN_DURATION_MASK_ =    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFFFFFF;
uint256 constant _LOAN_DURATION_MAP_ =     0x000000000000000000000000000000000000FFFFFFFF00000000000000000000;
uint256 constant _IS_FIXED_MASK_ =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFF;
uint256 constant _IS_FIXED_MAP_ =          0x00000000000000000000000000000000000F0000000000000000000000000000;
uint256 constant _COMMITAL_MASK_ =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
uint256 constant _COMMITAL_MAP_ =          0x000000000000000000000000000000000FF00000000000000000000000000000;
uint256 constant _LENDER_ROYALTIES_MASK_ = 0xFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
uint256 constant _LENDER_ROYALTIES_MAP_ =  0x00FF000000000000000000000000000000000000000000000000000000000000;
uint256 constant _LOAN_COUNT_MASK_ =       0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
uint256 constant _LOAN_COUNT_MAP_ =        0xFF00000000000000000000000000000000000000000000000000000000000000;
uint256 constant _CLEANUP_MASK_ =          0xFFFF00000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

uint8 constant _LOAN_STATE_POS_ = 0;
uint8 constant _FIR_INTERVAL_POS_ = 4;
uint8 constant _FIR_POS_ = 8;
uint8 constant _LOAN_START_POS_ = 16;
uint8 constant _LOAN_DURATION_POS_ = 80;
uint8 constant _IS_FIXED_POS_ = 112;
uint8 constant _COMMITAL_POS_ = 116;
uint8 constant _LENDER_ROYALTIES_POS_ = 240;
uint8 constant _LOAN_COUNT_POS_ = 248;

/* ------------------------------------------------ *
 *      Loan Manager Custom Error Selectors         *
 * ------------------------------------------------ */
bytes4 constant _INVALID_PARTICIPANT_SELECTOR_ = 0xa145c43e; // bytes4(keccak256("InvalidParticipant()"))
bytes4 constant _ILLEGAL_TERMS_UPDATE_SELECTOR_ = 0x75d55ed4; // bytes4(keccak256("IllegalTermsUpdate()"))

library StdManagerErrors {
    /* ------------------------------------------------ *
     *           Loan Manager Custom Errors             *
     * ------------------------------------------------ */
    error InvalidParticipant();
    error IllegalTermsUpdate();
}

interface ILoanCodec {
    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) external view returns (uint256);
}

interface IDebtTerms {
    function debtTerms(uint256 _debtId) external view returns (bytes32);

    function loanState(uint256 _debtId) external view returns (uint256);

    function firInterval(uint256 _debtId) external view returns (uint256);

    function fixedInterestRate(uint256 _debtId) external view returns (uint256);

    function isFixed(uint256 _debtId) external view returns (uint256);

    function loanLastChecked(uint256 _debtId) external view returns (uint256);

    function loanStart(uint256 _debtId) external view returns (uint256);

    function loanDuration(uint256 _debtId) external view returns (uint256);

    function loanCommital(uint256 _debtId) external view returns (uint256);

    function loanClose(uint256 _debtId) external view returns (uint256);

    function lenderRoyalties(uint256 _debtId) external view returns (uint256);

    function activeLoanCount(uint256 _debtId) external view returns (uint256);
}

// SPDX-Liscense-Identifier: MIT

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64, "fail");
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(
                        absoluteResult <=
                            0x8000000000000000000000000000000000000000000000000000000000000000
                    );
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(
                        absoluteResult <=
                            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                    );
                    return int256(absoluteResult);
                }
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) *
                (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(
                hi <=
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
                        lo
            );
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(
                m <
                    0x4000000000000000000000000000000000000000000000000000000000000000
            );
            return int128(sqrtu(uint256(m)));
        }
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(log_2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0)
                result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0)
                result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0)
                result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0)
                result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0)
                result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0)
                result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0)
                result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0)
                result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0)
                result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0)
                result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0)
                result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0)
                result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0)
                result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0)
                result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0)
                result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0)
                result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0)
                result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0)
                result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0)
                result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0)
                result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0)
                result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0)
                result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0)
                result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0)
                result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0)
                result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0)
                result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0)
                result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0)
                result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0)
                result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0)
                result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0)
                result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0)
                result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0)
                result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0)
                result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0)
                result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0)
                result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0)
                result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0)
                result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0)
                result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0)
                result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0)
                result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0)
                result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0)
                result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0)
                result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0)
                result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0)
                result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0)
                result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0)
                result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0)
                result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0)
                result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0)
                result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0)
                result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0)
                result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0)
                result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0)
                result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0)
                result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0)
                result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0)
                result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0)
                result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0)
                result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0)
                result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0)
                result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0)
                result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return
                exp_2(
                    int128(
                        (int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128
                    )
                );
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                result += xh == hi >> 128 ? xl / y : 1;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x4) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

/**
 * @title DebtTermIndexer
 * @author jjgarcia.eth
 * @notice The DebtTermIndexer library provides functions to index and set
 * the debt terms for a given debt ID.
 *
 * @dev The debt terms are packed into a single bytes32 value. The debt terms
 * are indexed as follows within the DebtTermMap.packedDebtTerms mapping:
 *  > 004 - [0..3]     `loanState`
 *  > 004 - [4..7]     `firInterval`
 *  > 008 - [8..15]    `fixedInterestRate`
 *  > 064 - [16..79]   `loanStart`
 *  > 032 - [80..111]  `loanDuration`
 *  > 004 - [112..115] `isFixed`
 *  > 008 - [116..123] `commital`
 *  > 160 - [124..239]  unused space
 *  > 008 - [240..247] `lenderRoyalties`
 *  > 008 - [248..255] `activeLoanIndex`
 *
 * Alternatively, see {LendingContractTermMaps} for mappings.
 */
library DebtTermIndexer {
    /**
     * The packed debt term mapping for each debt ID.
     *
     * @param packedDebtTerms The packed debt terms for each debt ID.
     */
    struct DebtTermMap {
        mapping(uint256 debtId => bytes32) packedDebtTerms;
    }

    /**
     * Modifier to ensure that the debt terms map has not been initialized
     * and can therefore be set.
     *
     * @param _packedDebtTerms The initialized debt terms.
     */
    modifier onlyUnlocked(bytes32 _packedDebtTerms) {
        __checkUnlocked(_packedDebtTerms);
        _;
    }

    /**
     * Returns the packed debt terms for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * @return The packed debt terms.
     */
    function _debtTerms(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (bytes32) {
        return _map.packedDebtTerms[_debtId];
    }

    /**
     * Sets the packed debt terms for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     * @param _packedDebtTerms The debt terms to set.
     */
    function _setDebtTerms(
        DebtTermMap storage _map,
        uint256 _debtId,
        bytes32 _packedDebtTerms
    ) internal onlyUnlocked(_map.packedDebtTerms[_debtId]) {
        _map.packedDebtTerms[_debtId] = _packedDebtTerms;
    }

    /**
     * Updates the packed debt terms for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     * @param _packedDebtTerms The debt terms to update to.
     */
    function _updateDebtTerms(
        DebtTermMap storage _map,
        uint256 _debtId,
        bytes32 _packedDebtTerms
    ) internal {
        _map.packedDebtTerms[_debtId] = _packedDebtTerms;
    }

    /**
     * Returns the loan state for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for the
     * `_LOAN_STATE_MAP_`.
     *
     * @return _uLoanState The unpacked loan state.
     */
    function _loanState(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanState) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }
    }

    /**
     * Returns the fixed interest rate (FIR) interval for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_FIR_INTERVAL_POS_`
     * and `_FIR_INTERVAL_MAP_`.
     *
     * @return _uFirInterval The unpacked FIR interval.
     */
    function _firInterval(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uFirInterval) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uFirInterval := shr(
                _FIR_INTERVAL_POS_,
                and(_contractTerms, _FIR_INTERVAL_MAP_)
            )
        }
    }

    /**
     * Returns the fixed interest rate (FIR) for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_FIR_POS_` and
     * `_FIR_MAP_`.
     *
     * @return _uFixedInterestRate The unpacked fixed interest rate.
     */
    function _fixedInterestRate(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uFixedInterestRate) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uFixedInterestRate := shr(
                _FIR_POS_,
                and(_contractTerms, _FIR_MAP_)
            )
        }
    }

    /**
     * Returns the is fixed status for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_IS_FIXED_POS_` and
     * `_IS_FIXED_MAP_`.
     *
     * @return _uIsFixed The unpacked is fixed status.
     */
    function _isFixed(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uIsFixed) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uIsFixed := shr(
                _IS_FIXED_POS_,
                and(_contractTerms, _IS_FIXED_MAP_)
            )
        }
    }

    /**
     * Returns the loan last checked timestamp for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * @return the loan last checked timestamp.
     */
    function _loanLastChecked(
        DebtTermMap storage _map,
        uint256 _debtId
    ) external view returns (uint256) {
        return _loanStart(_map, _debtId);
    }

    /**
     * Returns the loan start timestamp for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_START_POS_` and
     * `_LOAN_START_MAP_`.
     *
     * @return _uLoanStart The unpacked loan start timestamp.
     */
    function _loanStart(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanStart) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )
        }
    }

    /**
     * Returns the loan duration for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_DURATION_POS_`
     * and `_LOAN_DURATION_MAP_`.
     *
     * @return _uLoanDuration The unpacked loan duration.
     */
    function _loanDuration(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanDuration) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanDuration := shr(
                _LOAN_DURATION_POS_,
                and(_contractTerms, _LOAN_DURATION_MAP_)
            )
        }
    }

    /**
     * Returns the loan commital duration for a given debt ID.
     *
     * @dev The loan commital is the duration commitment of the borrower to
     * the lender.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_COMMITAL_POS_` and
     * `_COMMITAL_MAP_`.
     *
     * @return _uLoanCommital The unpacked loan commital duration.
     */
    function _loanCommital(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanCommital) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanCommital := shr(
                _COMMITAL_POS_,
                and(_contractTerms, _COMMITAL_MAP_)
            )
        }
    }

    /**
     * Returns the loan commital time for a given debt ID.
     *
     * TODO: This is a nice method, but currently unused. Remove?
     *
     * @dev The loan commital is the time commitment of the borrower to the
     * lender. Therefore, the if the current timestamp is within the loan
     * commital time, the borrower cannot sale the debt nor refinance it.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * @return _uLoanCommitalTime The unpacked loan commital time.
     */
    function _loanCommitalTime(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256) {
        int128 _uLoanStart = ABDKMath64x64.fromUInt(_loanStart(_map, _debtId));
        int128 _uLoanDuration = ABDKMath64x64.fromUInt(
            _loanDuration(_map, _debtId)
        );
        int128 _ratio = ABDKMath64x64.divu(_loanCommital(_map, _debtId), 100);
        int128 _commitalPeriod = ABDKMath64x64.mul(_uLoanDuration, _ratio);
        int128 _commitalTime = ABDKMath64x64.add(_uLoanStart, _commitalPeriod);

        return ABDKMath64x64.toUInt(_commitalTime);
    }

    /**
     * Returns the loan close timestamp for a given debt ID.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_START_POS_`,
     * `_LOAN_START_MAP_`, `_LOAN_DURATION_POS_`, and `_LOAN_DURATION_MAP_`.
     *
     * @return _uLoanClose The unpacked loan close timestamp.
     */
    function _loanClose(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLoanClose) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLoanClose := add(
                shr(_LOAN_START_POS_, and(_contractTerms, _LOAN_START_MAP_)),
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )
        }
    }

    /**
     * Returns the lender royalties on a refinance transaction to another
     * lender.
     *
     * @dev If the lender royalties is 0, the lender will not receive any
     * royalties on a refinance transaction. The lender royalties is a
     * percentage of the interest paid by the borrower to the lender.
     * Therefore, it must be within the range of 0 - 100.
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for
     * `_LENDER_ROYALTIES_POS_` and `_LENDER_ROYALTIES_MAP_`.
     *
     * @return _uLenderRoyalties The unpacked lender royalties.
     */
    function _lenderRoyalties(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uLenderRoyalties) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uLenderRoyalties := shr(
                _LENDER_ROYALTIES_POS_,
                and(_contractTerms, _LENDER_ROYALTIES_MAP_)
            )
        }
    }

    /**
     * Returns the active loan count of a given collateralized token.
     *
     * TODO: This is not used anywhere. It is also captured in the DebtMaps
     * database. Remove?
     *
     * @param _map The debt term map.
     * @param _debtId The debt ID.
     *
     * See {lending-constants/LoanContractTermMaps} for `_LOAN_COUNT_POS_` and
     * `_LOAN_COUNT_MAP_`.
     *
     * @return _uActiveLoanCount The unpacked active loan count.
     */
    function _activeLoanCount(
        DebtTermMap storage _map,
        uint256 _debtId
    ) internal view returns (uint256 _uActiveLoanCount) {
        bytes32 _contractTerms = _map.packedDebtTerms[_debtId];

        assembly {
            _uActiveLoanCount := shr(
                _LOAN_COUNT_POS_,
                and(_contractTerms, _LOAN_COUNT_MAP_)
            )
        }
    }

    /**
     * Reverts with a illegal terms update error if the debt ID terms are
     * already in use.
     *
     * @param _packedDebtTerms The packed debt terms.
     */
    function __checkUnlocked(bytes32 _packedDebtTerms) private pure {
        assembly {
            if gt(_packedDebtTerms, 0) {
                mstore(0x20, _ILLEGAL_TERMS_UPDATE_SELECTOR_)
                revert(0x20, 0x04)
            }
        }
    }
}

abstract contract DebtTerms is IDebtTerms {
    using DebtTermIndexer for DebtTermIndexer.DebtTermMap;

    /**
     * The packed debt terms for each debt ID.
     *
     * See {DebtTermIndexer.packedDebtTerms}.
     */
    DebtTermIndexer.DebtTermMap private __packedDebtTerms;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IDebtTerms).interfaceId;
    }

    /**
     * Returns the packed debt terms for a given debt ID.
     *
     * @param _debtId The debt ID to return the packed debt terms for.
     *
     * See {DebtTermIndexer._debtTerms}.
     *
     * @return The packed debt terms for the given debt ID.
     */
    function debtTerms(uint256 _debtId) public view returns (bytes32) {
        return __packedDebtTerms._debtTerms(_debtId);
    }

    /**
     * Sets the packed debt terms for a given debt ID.
     *
     * @param _debtId The debt ID to set the packed debt terms for.
     *
     * See {DebtTermIndexer._setDebtTerms}.
     */
    function _setDebtTerms(uint256 _debtId, bytes32 _packedDebtTerms) internal {
        __packedDebtTerms._setDebtTerms(_debtId, _packedDebtTerms);
    }

    /**
     * Updates the packed debt terms for a given debt ID.
     *
     * @param _debtId The debt ID to update the packed debt terms.
     *
     * See {DebtTermIndexer._updateDebtTerms}.
     */
    function _updateDebtTerms(
        uint256 _debtId,
        bytes32 _packedDebtTerms
    ) internal {
        __packedDebtTerms._updateDebtTerms(_debtId, _packedDebtTerms);
    }

    /**
     * Returns the loan state for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan state for.
     *
     * See {DebtTermIndexer._loanState}.
     *
     * @return The loan state for the given debt ID.
     */
    function loanState(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanState(_debtId);
    }

    /**
     * Returns the fixed interest rate (FIR) interval for a given debt ID.
     *
     * @param _debtId The debt ID to return the FIR interval for.
     *
     * See {DebtTermIndexer._firInterval}.
     *
     * @return The FIR interval for the given debt ID.
     */
    function firInterval(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._firInterval(_debtId);
    }

    /**
     * Returns the fixed interest rate (FIR) for a given debt ID.
     *
     * @param _debtId The debt ID to return the FIR for.
     *
     * See {DebtTermIndexer._fixedInterestRate}.
     *
     * @return The FIR for the given debt ID.
     */
    function fixedInterestRate(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._fixedInterestRate(_debtId);
    }

    /**
     * Returns the is fixed status for a given debt ID.
     *
     * @param _debtId The debt ID to return the is fixed status for.
     *
     * See {DebtTermIndexer._isFixed}.
     *
     * @return The is fixed status for the given debt ID.
     */
    function isFixed(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._isFixed(_debtId);
    }

    /**
     * Returns the loan last checked timestamp for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan last checked
     * timestamp for.
     *
     * See {DebtTermIndexer._loanLastChecked}.
     *
     * @return The loan last checked timestamp for the given debt ID.
     */
    function loanLastChecked(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanLastChecked(_debtId);
    }

    /**
     * Returns the loan start timestamp for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan start timestamp for.
     *
     * See {DebtTermIndexer._loanStart}.
     *
     * @return The loan start timestamp for the given debt ID.
     */
    function loanStart(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanStart(_debtId);
    }

    /**
     * Returns the loan duration for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan duration for.
     *
     * See {DebtTermIndexer._loanDuration}.
     *
     * @return The loan duration for the given debt ID.
     */
    function loanDuration(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanDuration(_debtId);
    }

    /**
     * Returns the loan commital duration for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan commital duration for.
     *
     * See {DebtTermIndexer._loanCommital}.
     *
     * @return The loan commital duration for the given debt ID.
     */
    function loanCommital(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanCommital(_debtId);
    }

    /**
     * Returns the loan close timestamp for a given debt ID.
     *
     * @param _debtId The debt ID to return the loan close timestamp for.
     *
     * See {DebtTermIndexer._loanClose}.
     *
     * @return The loan close timestamp for the given debt ID.
     */
    function loanClose(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._loanClose(_debtId);
    }

    /**
     * Returns the lender royalties on a refinance transaction to another lender.
     *
     * @param _debtId The debt ID to return the lender royalties for.
     *
     * See {DebtTermIndexer._lenderRoyalties}.
     *
     * @return The lender royalties for the given debt ID.
     */
    function lenderRoyalties(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._lenderRoyalties(_debtId);
    }

    /**
     * Returns the active loan count of a given collateralized token.
     *
     * TODO: This is not used anywhere. It is also captured in the DebtMaps
     * database. Remove?
     *
     * @param _debtId The debt ID to return the active loan count for.
     *
     * See {DebtTermIndexer._activeLoanCount}.
     *
     * @return The active loan count for the given debt ID.
     */
    function activeLoanCount(uint256 _debtId) public view returns (uint256) {
        return __packedDebtTerms._activeLoanCount(_debtId);
    }
}

bytes4 constant _OVERFLOW_CAST_SELECTOR_ = 0x94c4b548; // bytes4(keccak256("OverlflowCast()"))

library TypeUtils {
    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function _toUint64(uint256 value) internal pure returns (uint64 _value) {
        assembly {
            if gt(value, _UINT64_MAX_) {
                mstore(0x20, _OVERFLOW_CAST_SELECTOR_)
                revert(0x20, 0x04)
            }

            _value := value
        }
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function _toUint32(uint256 value) internal pure returns (uint32 _value) {
        assembly {
            if gt(value, _UINT32_MAX_) {
                mstore(0x20, _OVERFLOW_CAST_SELECTOR_)
                revert(0x20, 0x04)
            }

            _value := value
        }
    }

    /**
     * @dev Validates that the input value fits into a uint32.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function _verifyUint32(uint256 value) internal pure {
        assembly {
            if gt(value, _UINT32_MAX_) {
                mstore(0x20, _OVERFLOW_CAST_SELECTOR_)
                revert(0x20, 0x04)
            }
        }
    }
}

/**
 * @title InterestCalculator
 * @author jjgarcia.eth
 * @notice The InterestCalculator library provides functions to calculate interest
 * of a debt account.
 *
 * @dev This library is a interface for using the ABDKMath64x64 library for
 * interest calculations.
 *
 * See {ABDKMath64x64}.
 */
library InterestCalculator {
    function compoundWithTopoff(
        uint256 _principal,
        uint256 _ratio,
        uint256 _n
    ) public pure returns (uint256) {
        return
            compound(_principal, _ratio, _n) + topoff(_principal, _ratio, _n);
    }

    function compound(
        uint256 _principal,
        uint256 _ratio,
        uint256 _n
    ) public pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(_ratio, 100)
                    ),
                    _n
                ),
                _principal
            );
    }

    function pow(int128 _x, uint256 _n) public pure returns (int128) {
        int128 _r = ABDKMath64x64.fromUInt(1);

        while (_n > 0) {
            if (_n % 2 == 1) {
                _r = ABDKMath64x64.mul(_r, _x);
                _n -= 1;
            } else {
                _x = ABDKMath64x64.mul(_x, _x);
                _n /= 2;
            }
        }

        return _r;
    }

    // Topoff to account for small inaccuracies in compound calculations
    function topoff(
        uint256 _totalDebt,
        uint256 _fixedInterestRate,
        uint256 _firIntervals
    ) public pure returns (uint256) {
        return
            _fixedInterestRate == 100 ? 0 : _fixedInterestRate >= 10
                ? _firIntervals == 1 && _totalDebt >= 10
                    ? 1
                    : _totalDebt >= 1000
                    ? (_totalDebt / (10 ** 21)) >= 1 ? 10 : 1
                    : 0
                : _fixedInterestRate == 1
                ? _firIntervals == 1 && _totalDebt >= 100
                    ? (_totalDebt / (10 ** 21)) >= 1 ? 10 : 1
                    : 0
                : 0;
    }
}

abstract contract LoanCodec is ILoanCodec, DebtTerms {
    using TypeUtils for uint256;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(DebtTerms) returns (bool) {
        return
            DebtTerms.supportsInterface(_interfaceId) ||
            _interfaceId == type(ILoanCodec).interfaceId;
    }

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) public view returns (uint256) {
        // Verify _seconds fits into a uint32.
        _seconds._verifyUint32();

        // Determine the max number of seconds that can be calculated.
        _seconds = (_seconds + loanLastChecked(_debtId)) <= loanClose(_debtId)
            ? _seconds
            : loanDuration(_debtId);

        // Return the total number of FIR intervals.
        return _getTotalFirIntervals(firInterval(_debtId), _seconds);
    }

    function _validateLoanTerms(
        bytes32 _contractTerms,
        uint64 _loanStart,
        uint256 _principal
    ) internal pure {
        if (_principal == 0)
            revert StdCodecErrors.InvalidLoanParameter(_PRINCIPAL_ERROR_ID_);

        uint32 _duration;
        uint8 _fixedInterestRate;
        uint8 _firInterval;

        assembly {
            function __revert(_errId) {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _errId)
                revert(0x20, 0x08)
            }

            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            let _lenderRoyalties := and(mload(0), _UINT8_MAX_)

            if gt(_lenderRoyalties, 0x64) {
                __revert(_LENDER_ROYALTIES_ERROR_ID_)
            }

            // Get packed terms expiry
            mstore(0x1b, _contractTerms)
            let _termsExpiry := and(mload(0), _UINT32_MAX_)

            if lt(_termsExpiry, _SECONDS_PER_24_MINUTES_RATIO_SCALED_) {
                __revert(_TIME_EXPIRY_ERROR_ID_)
            }

            // Get packed duration
            mstore(0x17, _contractTerms)
            _duration := and(mload(0), _UINT32_MAX_)

            if iszero(_duration) {
                __revert(_DURATION_ERROR_ID_)
            }

            // Get packed grace period
            mstore(0x13, _contractTerms)
            let _gracePeriod := and(mload(0), _UINT32_MAX_)

            // This will effectively eliminate flash loans.
            // TODO: Consider adding in an acceptable condition where both are
            // zero for flash loans.
            if iszero(lt(_gracePeriod, _duration)) {
                __revert(_GRACE_PERIOD_ERROR_ID_)
            }

            if gt(add(add(_loanStart, _duration), _gracePeriod), _UINT32_MAX_) {
                __revert(_DURATION_ERROR_ID_)
            }

            // Get fixed interest rate
            mstore(0x01, _contractTerms)
            _fixedInterestRate := and(mload(0), _UINT8_MAX_)

            // Get fir interval
            mstore(0x00, _contractTerms)
            _firInterval := and(mload(0), _UINT8_MAX_)

            if gt(_firInterval, 15) {
                __revert(_FIR_INTERVAL_ERROR_ID_)
            }
        }

        // Check max compounded debt
        try
            InterestCalculator.compoundWithTopoff(
                _principal,
                _fixedInterestRate,
                _getTotalFirIntervals(_firInterval, _duration)
            )
        returns (uint256) {} catch {
            if (_firInterval != 0)
                revert StdCodecErrors.InvalidLoanParameter(
                    _FIXED_INTEREST_RATE_ERROR_ID_
                );
        }
    }

    /**
     * Returns the total number of fir intervals in a given duration of seconds.
     *
     * @notice This function intentionally uses unsafe division.
     *
     * @param _firInterval The fir interval to use.
     * @param _seconds The duration in seconds.
     *
     * @dev Reverts if `_firInterval` is not a valid fir interval.
     *
     * See {LoanContractFIRIntervals} for valid fir intervals.
     *
     * @return _totalFirIntervals The total number of fir intervals.
     */
    function _getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) internal pure returns (uint256 _totalFirIntervals) {
        assembly {
            switch _firInterval
            // _SECONDLY_
            case 0 {
                _totalFirIntervals := _seconds
            }
            // _MINUTELY_
            case 1 {
                _totalFirIntervals := div(_seconds, _MINUTELY_MULTIPLIER_)
            }
            // _HOURLY_
            case 2 {
                _totalFirIntervals := div(_seconds, _HOURLY_MULTIPLIER_)
            }
            // _DAILY_
            case 3 {
                _totalFirIntervals := div(_seconds, _DAILY_MULTIPLIER_)
            }
            // _WEEKLY_
            case 4 {
                _totalFirIntervals := div(_seconds, _WEEKLY_MULTIPLIER_)
            }
            // _2_WEEKLY_
            case 5 {
                _totalFirIntervals := div(_seconds, _2_WEEKLY_MULTIPLIER_)
            }
            // _4_WEEKLY_
            case 6 {
                _totalFirIntervals := div(_seconds, _4_WEEKLY_MULTIPLIER_)
            }
            // _6_WEEKLY_
            case 7 {
                _totalFirIntervals := div(_seconds, _6_WEEKLY_MULTIPLIER_)
            }
            // _8_WEEKLY_
            case 8 {
                _totalFirIntervals := div(_seconds, _8_WEEKLY_MULTIPLIER_)
            }
            // _360_DAILY_
            case 14 {
                _totalFirIntervals := div(_seconds, _360_DAILY_MULTIPLIER_)
            }
            // Invalid fir interval
            default {
                mstore(0x20, _INVALID_LOAN_PARAMETER_SELECTOR_)
                mstore(0x24, _FIR_INTERVAL_ERROR_ID_)
                revert(0x20, 0x08)
            }
        }
    }

    function _setLoanAgreement(
        uint64 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) internal {
        bytes32 _loanAgreement;

        assembly {
            function __packTerm(_mask, _map, _pos, _val) {
                mstore(
                    0x20,
                    xor(and(_mask, mload(0x20)), and(_map, shl(_pos, _val)))
                )
            }

            // Get packed fixed interest rate
            mstore(0x01, _contractTerms)
            let _fixedInterestRate := and(mload(0), _UINT8_MAX_)

            // Get packed is direct and commital
            // Need to mask other packed terms for gt
            // comparison below.
            mstore(0x02, _contractTerms)
            let _isDirect_Commital := and(mload(0), _UINT8_MAX_)

            // Get packed grace period
            mstore(0x13, _contractTerms)
            let _gracePeriod := and(mload(0), _UINT32_MAX_)

            // Get packed duration
            mstore(0x17, _contractTerms)
            let _duration := and(mload(0), _UINT32_MAX_)

            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            let _lenderRoylaties := and(mload(0), _UINT8_MAX_)

            // Shif left to make space for loan state
            mstore(0x20, shl(4, _contractTerms))

            // Pack loan state (uint4)
            switch iszero(_gracePeriod)
            case 1 {
                __packTerm(
                    _LOAN_STATE_MASK_,
                    _LOAN_STATE_MAP_,
                    _LOAN_STATE_POS_,
                    _ACTIVE_STATE_
                )
            }
            default {
                __packTerm(
                    _LOAN_STATE_MASK_,
                    _LOAN_STATE_MAP_,
                    _LOAN_STATE_POS_,
                    _ACTIVE_GRACE_STATE_
                )
            }

            // Pack fir interval (uint4)
            // Already performed and not needed.

            // Pack fixed interest rate (uint8)
            __packTerm(_FIR_MASK_, _FIR_MAP_, _FIR_POS_, _fixedInterestRate)

            // Pack loan start time (uint64)
            __packTerm(
                _LOAN_START_MASK_,
                _LOAN_START_MAP_,
                _LOAN_START_POS_,
                add(_now, _gracePeriod)
            )

            // Pack loan duration time (uint32)
            __packTerm(
                _LOAN_DURATION_MASK_,
                _LOAN_DURATION_MAP_,
                _LOAN_DURATION_POS_,
                sub(_duration, _gracePeriod)
            )

            switch gt(_isDirect_Commital, 0x64)
            case true {
                // Pack is direct (uint4) - true
                __packTerm(
                    _IS_FIXED_MASK_,
                    _IS_FIXED_MAP_,
                    _IS_FIXED_POS_,
                    0x01
                )

                // Pack commital (uint8)
                __packTerm(
                    _COMMITAL_MASK_,
                    _COMMITAL_MAP_,
                    _COMMITAL_POS_,
                    sub(_isDirect_Commital, 0x65)
                )
            }
            case false {
                // Pack is direct (uint4) - false
                __packTerm(
                    _IS_FIXED_MASK_,
                    _IS_FIXED_MAP_,
                    _IS_FIXED_POS_,
                    0x00
                )

                // Pack commital (uint8)
                __packTerm(
                    _COMMITAL_MASK_,
                    _COMMITAL_MAP_,
                    _COMMITAL_POS_,
                    _isDirect_Commital
                )
            }

            // Pack lender royalties (uint8)
            __packTerm(
                _LENDER_ROYALTIES_MASK_,
                _LENDER_ROYALTIES_MAP_,
                _LENDER_ROYALTIES_POS_,
                _lenderRoylaties
            )

            // Pack loan count (uint8)
            __packTerm(
                _LOAN_COUNT_MASK_,
                _LOAN_COUNT_MAP_,
                _LOAN_COUNT_POS_,
                _activeLoanIndex
            )

            _loanAgreement := and(_CLEANUP_MASK_, mload(0x20))
        }

        _setDebtTerms(_debtId, _loanAgreement);
    }

    function _updateLoanState(uint256 _debtId, uint8 _newLoanState) internal {
        bytes32 _contractTerms = debtTerms(_debtId);
        uint8 _oldLoanState;

        assembly {
            _oldLoanState := and(_LOAN_STATE_MAP_, _contractTerms)

            // If the loan states are the same or the new loan state is
            // greater than the max loan state, revert.
            if or(eq(_oldLoanState, _newLoanState), gt(_newLoanState, 0x0f)) {
                mstore(0x20, _ILLEGAL_TERMS_UPDATE_SELECTOR_)
                revert(0x20, 0x04)
            }

            mstore(0x20, _contractTerms)

            mstore(
                0x20,
                xor(
                    and(_LOAN_STATE_MASK_, mload(0x20)),
                    and(_LOAN_STATE_MAP_, _newLoanState)
                )
            )

            _contractTerms := mload(0x20)
        }

        _updateDebtTerms(_debtId, _contractTerms);

        emit LoanStateChanged(_debtId, _newLoanState, _oldLoanState);
    }

    /**
     * Updates the loan times.
     *
     * TODO: Need to account for grace periods.
     *
     * @param _debtId The debt id.
     * @param _updateType The type of update. If this is invoked, it will be
     * returned directly by the caller.
     */
    function _updateLoanTimes(
        uint256 _debtId,
        uint256 _updateType
    ) internal returns (uint256) {
        bytes32 _contractTerms = debtTerms(_debtId);

        assembly {
            // If loan state is beyond active, do nothing.
            if gt(and(_LOAN_STATE_MAP_, _contractTerms), _ACTIVE_STATE_) {
                mstore(0x20, _ILLEGAL_TERMS_UPDATE_SELECTOR_)
                revert(0x20, 0x04)
            }

            mstore(0x20, _contractTerms)

            // Store loan start time
            let _loanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )

            let _now := timestamp()
            if iszero(gt(_now, _loanStart)) {
                mstore(0x20, _updateType)
                return(0x20, 0x20)
            }

            // Store loan close time
            let _loanClose := add(
                _loanStart,
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )

            if gt(_now, _loanClose) {
                _now := _loanClose
            }

            mstore(
                0x20,
                xor(
                    and(_LOAN_START_MASK_, mload(0x20)),
                    and(_LOAN_START_MAP_, shl(_LOAN_START_POS_, _now))
                )
            )

            mstore(
                0x20,
                xor(
                    and(_LOAN_DURATION_MASK_, mload(0x20)),
                    and(
                        _LOAN_DURATION_MAP_,
                        shl(_LOAN_DURATION_POS_, sub(_loanClose, _now))
                    )
                )
            )

            _contractTerms := mload(0x20)
        }

        _updateDebtTerms(_debtId, _contractTerms);

        return 1;
    }
}

interface IDebtBook {
    struct DebtMap {
        uint256 debtId;
        uint256 collateralNonce;
    }

    function totalDebts() external returns (uint256);

    function debtBalance(uint256 debtId) external view returns (uint256);

    function lenderDebtBalance(
        uint256 _debtId
    ) external view returns (uint256 debtBalance);

    function borrowerDebtBalance(
        uint256 _debtId
    ) external view returns (uint256 debtBalance);

    function collateralDebtBalance(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256 debtBalance);

    function collateralDebtCount(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function collateralDebtAt(
        uint256 _debtId,
        uint256 _index
    ) external view returns (uint256 debtId, uint256 collateralNonce);

    function collateralDebtAt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _index
    ) external view returns (uint256 debtId, uint256 collateralNonce);

    function collateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256 collateralNonce);
}

bytes4 constant _INVALID_ADDRESS_ERROR_ID_ = 0xe6c4247b;

library StdAccessErrors {
    /* ------------------------------------------------ *
     *            Marketplace Custom Errors             *
     * ------------------------------------------------ */
    error InvalidAddress();
}

interface IDebtBookAccessController {
    function anzaToken() external returns (address);

    function collateralVault() external returns (address);

    function setAnzaToken(address _anzaTokenAddress) external;

    function setCollateralVault(address _collateralVaultAddress) external;
}

interface IAnzaToken {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function debtId(uint256 _tokenId) external pure returns (uint256);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /// @notice Get the borrower of a debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The borrower of the debt.
    function borrowerOf(uint256 _debtId) external view returns (address);

    /// @notice Get the lender of a debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The lender of the debt.
    function lenderOf(uint256 _debtId) external view returns (address);

    /// @notice Get the borrower token ID for a given debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The borrower token ID of the debt.
    function borrowerTokenId(uint256 _debtId) external pure returns (uint256);

    /// @notice Get the lender token ID for a given debt.
    /// @param _debtId The debt ID of the loan.
    /// @return The lender token ID of the debt.
    function lenderTokenId(uint256 _debtId) external pure returns (uint256);

    /// @dev Total amount of tokens in with a given id.
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// - MUST revert on any other error.
    /// - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// - After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _debtId ID of the token type
    /// @param _amount Transfer amount
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /// @notice Send multiple types of Tokens from the `_from` address to the `_to` address (with safety call).
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _debtIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    /// @param _debtId argument MUST be the debt ID for deriving token ID being transferred.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    function mint(uint256 _debtId, uint256 _amount) external;

    /// @param _to argument MUST be the address of the recipient whose balance is increased.
    /// @param _debtId argument MUST be the debt ID for deriving token ID being transferred.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function mint(
        address _to,
        uint256 _debtId,
        uint256 _amount,
        bytes memory _data
    ) external;

    /// @param _to argument MUST be the address of the recipient whose balance is increased.
    /// @param _id argument MUST be the token ID being transferred.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string calldata _collateralURI,
        bytes memory _data
    ) external;

    /// @param _account argument MUST be the address of the owner/operator whose balance is decreased.
    /// @param _id argument MUST be the token being burned.
    /// @param _amount argument MUST be the number of tokens the holder balance is decreased by.
    function burn(address _account, uint256 _id, uint256 _amount) external;

    /// @param _address argument MUST be the address of the owner/operator whose balance is decreased.
    /// @param _ids argument MUST be the tokens being burned.
    /// @param _amounts argument MUST be the number of tokens the holder balance is decreased by.
    function burnBatch(
        address _address,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    /// @param _debtId argument MUST be the debt ID for deriving token ID being burned.
    function burnBorrowerToken(uint256 _debtId) external;

    /// @param _debtId argument MUST be the debt ID for deriving token ID being burned.
    /// @param _debtId argument MUST be the debt ID for deriving token ID being burned.
    function burnLenderToken(uint256 _debtId, uint256 _amount) external;
}

abstract contract DebtBookAccessController {
    IAnzaToken internal _anzaToken;
    ICollateralVault internal _collateralVault;

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IDebtBookAccessController).interfaceId;
    }

    /**
     * Returns the Anza Token contract address.
     */
    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    /**
     * Returns the Collateral Vault contract address.
     */
    function collateralVault() external view returns (address) {
        return address(_collateralVault);
    }

    /**
     * Call to set the Anza Token contract.
     *
     * @param _anzaTokenAddress The address of the Anza Token contract.
     */
    function setAnzaToken(address _anzaTokenAddress) public virtual;

    /**
     * Call to set the Collateral Vault contract.
     *
     * @param _collateralVaultAddress The address of the Collateral Vault
     * contract.
     */
    function setCollateralVault(address _collateralVaultAddress) public virtual;

    /**
     * Sets the Anza Token contract.
     *
     * @param _anzaTokenAddress The address of the Anza Token contract.
     */
    function _setAnzaToken(address _anzaTokenAddress) internal {
        __verifyAddress(_anzaTokenAddress);

        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    /**
     * Sets the Collateral Vault contract.
     *
     * @param _collateralVaultAddress The address of the Collateral Vault contract.
     */
    function _setCollateralVault(address _collateralVaultAddress) internal {
        __verifyAddress(_collateralVaultAddress);

        _collateralVault = ICollateralVault(_collateralVaultAddress);
    }

    function __verifyAddress(address _account) private pure {
        assembly {
            if iszero(_account) {
                mstore(0x20, _INVALID_ADDRESS_ERROR_ID_)
                revert(0x20, 0x04)
            }
        }
    }
}

/**
 * @title DebtBook
 * @author jjgarcia.eth
 * @notice A contract for managing debt.
 */
abstract contract DebtBook is IDebtBook, DebtBookAccessController {
    // Count of total inactive/active debts
    uint256 public totalDebts;

    // Mapping from collateral to debt
    mapping(address collateralAddress => mapping(uint256 collateralId => DebtMap[]))
        private __debtMaps;

    constructor() DebtBookAccessController() {}

    modifier onlyValidCollateral(address _collateralAddress) {
        if (_collateralAddress == address(0))
            revert StdLoanErrors.InvalidCollateral();
        _;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(DebtBookAccessController) returns (bool) {
        return
            _interfaceId == type(IDebtBook).interfaceId ||
            DebtBookAccessController.supportsInterface(_interfaceId);
    }

    /* ------------------------------------------------ *
     *                      Getters                     *
     * ------------------------------------------------ */
    /**
     * Returns the total debt balance for a debt ID.
     *
     * @param _debtId The debt ID to find the balance for.
     *
     * @return The total debt balance for the debt ID.
     */
    function debtBalance(uint256 _debtId) public view returns (uint256) {
        return _anzaToken.totalSupply(_anzaToken.lenderTokenId(_debtId));
    }

    /**
     * Returns the debt balance for a lender for a given debt ID.
     *
     * @param _debtId The debt ID to find the balance for.
     *
     * @return The debt balance for the lender for the debt ID.
     */
    function lenderDebtBalance(uint256 _debtId) public view returns (uint256) {
        return
            _anzaToken.balanceOf(
                _anzaToken.lenderOf(_debtId),
                _anzaToken.lenderTokenId(_debtId)
            );
    }

    /**
     * Returns the debt balance for a borrower for a given debt ID.
     *
     * @param _debtId The debt ID to find the balance for.
     *
     * @return The debt balance for the borrower for the debt ID.
     */
    function borrowerDebtBalance(
        uint256 _debtId
    ) public view returns (uint256) {
        return
            _anzaToken.balanceOf(
                _anzaToken.borrowerOf(_debtId),
                _anzaToken.borrowerTokenId(_debtId)
            );
    }

    /**
     * Returns the full count of the debt balance for a given collateral
     * token (i.e. the number of ADT held by lenders for this collateral).
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return _debtBalance The full count of the debt balance for the collateral.
     */
    function collateralDebtBalance(
        address _collateralAddress,
        uint256 _collateralId
    )
        public
        view
        onlyValidCollateral(_collateralAddress)
        returns (uint256 _debtBalance)
    {
        DebtMap[] memory _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        for (uint256 i; i < _debtMaps.length; ) {
            _debtBalance += _anzaToken.totalSupply(
                _anzaToken.lenderTokenId(_debtMaps[i].debtId)
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Returns the number of debt maps for a collateral.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return The number of debt maps for the collateral.
     */
    function collateralDebtCount(
        address _collateralAddress,
        uint256 _collateralId
    ) external view onlyValidCollateral(_collateralAddress) returns (uint256) {
        return __debtMaps[_collateralAddress][_collateralId].length;
    }

    function collateralDebtAt(
        uint256 _debtId,
        uint256 _index
    ) public view returns (uint256, uint256) {
        ICollateralVault.Collateral memory _collateral = _collateralVault
            .getCollateral(_debtId);

        return
            collateralDebtAt(
                _collateral.collateralAddress,
                _collateral.collateralId,
                _index
            );
    }

    /**
     * Returns the debt map for a collateral at a given index.
     *
     * @notice If the index is type(uint256).max, the latest debt map is returned.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     * @param _index The index of the debt map to return.
     *
     * Reverts if the index is out of bounds and not type(uint256).max.
     *
     * @return The debt map at the given index.
     */
    function collateralDebtAt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _index
    )
        public
        view
        onlyValidCollateral(_collateralAddress)
        returns (uint256, uint256)
    {
        DebtMap[] memory _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // Allow an easy way to return the latest debt
        if (_index == type(uint256).max)
            return (
                _debtMaps[_debtMaps.length - 1].debtId,
                _debtMaps[_debtMaps.length - 1].collateralNonce
            );

        // Return the debt at the index
        return (_debtMaps[_index].debtId, _debtMaps[_index].collateralNonce);
    }

    /**
     * Returns the nonce of the next loan contract for a collateral.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return The nonce of the next loan contract for a collateral.
     */
    function collateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) public view onlyValidCollateral(_collateralAddress) returns (uint256) {
        if (__debtMaps[_collateralAddress][_collateralId].length == 0) return 1;

        (, uint256 _collateralNonce) = collateralDebtAt(
            _collateralAddress,
            _collateralId,
            type(uint256).max
        );

        return _collateralNonce + 1;
    }

    /* ------------------------------------------------ *
     *                      Setters                     *
     * ------------------------------------------------ */
    /**
     * Wrapper function for writing a debt to the database.
     *
     * @dev This function should be called directly for initializing a loan
     * contract.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return _debtMapsLength The length of the debt maps for the collateral.
     * @return _collateralNonce The collateral nonce for the debt.
     */
    function _writeDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) internal returns (uint256, uint256) {
        return _writeDebt(_collateralAddress, _collateralId, ++totalDebts);
    }

    /**
     * Writes a debt to the database.
     *
     * @dev This function should only be called directly for revoking a loan
     * contract proposal with debt ID type(uint256).max. Revoking a loan
     * contract proposal is accomplished here by using up the collateral nonce.
     *
     * @notice This function will clear all previous debts for the collateral.
     * @notice This function will always increment the collateral nonce by 1.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     * @param _debtId The ID of the debt.
     *
     * @return _debtMapsLength The active loan count for this series of loans.
     * Note, this will always be 1 for this write function.
     * @return _collateralNonce The collateral nonce for the debt.
     */
    function _writeDebt(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
    ) internal returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        // Set debt
        DebtMap[] storage _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // Record new collateral nonce
        _collateralNonce = _debtMaps.length == 0
            ? 1
            : _debtMaps[_debtMaps.length - 1].collateralNonce + 1;

        // Clear previous debts
        delete __debtMaps[_collateralAddress][_collateralId];

        // Set debt fields
        _debtMaps.push(
            DebtMap({debtId: _debtId, collateralNonce: _collateralNonce})
        );

        return (1, _collateralNonce);
    }

    /**
     * Appends a debt to the database.
     *
     * @notice This function will not clear previous debts for the collateral.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     *
     * @return _debtMapsLength The new length of the debt map array.
     * @return _collateralNonce The collateral nonce for the debt.
     */
    function _appendDebt(
        address _collateralAddress,
        uint256 _collateralId
    ) internal returns (uint256 _debtMapsLength, uint256 _collateralNonce) {
        // Set debt
        DebtMap[] storage _debtMaps = __debtMaps[_collateralAddress][
            _collateralId
        ];

        // Record new collateral nonce
        _collateralNonce = _debtMaps[_debtMaps.length - 1].collateralNonce + 1;

        // Set debt fields
        _debtMaps.push(
            DebtMap({debtId: ++totalDebts, collateralNonce: _collateralNonce})
        );

        return (_debtMaps.length, _collateralNonce);
    }
}

interface IManagerAccessController {
    function loanTreasurer() external returns (address);
}

// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

abstract contract ManagerAccessController is
    IManagerAccessController,
    AccessControl
{
    address internal _loanTreasurerAddress;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl) returns (bool) {
        return
            _interfaceId == type(IManagerAccessController).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /**
     * Returns the Loan Treasurer contract address.
     */
    function loanTreasurer() external view returns (address) {
        return _loanTreasurerAddress;
    }

    /**
     * Overriding the default grantRole function to set the Loan Treasurer
     * address as the _TREASURER_ role holder.
     *
     * @param _role The role to grant.
     * @param _account The address to grant the role to.
     */
    function _grantRole(
        bytes32 _role,
        address _account
    ) internal virtual override(AccessControl) {
        (_role == _TREASURER_)
            ? __setLoanTreasurer(_account)
            : super._grantRole(_role, _account);
    }

    /**
     * Sets the Loan Treasurer address, revokes the _TREASURER_ role from the
     * previous Loan Treasurer, and grants the _TREASURER_ role to the new loan
     * treasurer address.
     *
     * @param _treasurer The address of the new loan treasurer.
     */
    function __setLoanTreasurer(address _treasurer) private {
        _revokeRole(_TREASURER_, _loanTreasurerAddress);
        super._grantRole(_TREASURER_, _treasurer);

        _loanTreasurerAddress = _treasurer;
    }
}

abstract contract LoanManager is
    ILoanManager,
    LoanCodec,
    DebtBook,
    ManagerAccessController
{
    constructor() ManagerAccessController() {}

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(LoanCodec, DebtBook, ManagerAccessController)
        returns (bool)
    {
        return
            _interfaceId == type(ILoanManager).interfaceId ||
            LoanCodec.supportsInterface(_interfaceId) ||
            DebtBook.supportsInterface(_interfaceId) ||
            ManagerAccessController.supportsInterface(_interfaceId);
    }

    function maxRefinances() public pure returns (uint256) {
        return _MAX_REFINANCES_;
    }

    /**
     * Function to set the Anza Token address.
     *
     * @param _anzaToken The Anza Token address.
     *
     * @dev This function is only callable by the _ADMIN_ role.
     */
    function setAnzaToken(
        address _anzaToken
    ) public virtual override onlyRole(_ADMIN_) {
        super._setAnzaToken(_anzaToken);
    }

    /**
     * Checked public call to set the Collateral Vault address.
     *
     * @notice This function fullfills the DebtBook signature.
     *
     * @param _collateralVault The Collateral Vault address.
     *
     * @dev This function is only callable by the _ADMIN_ role.
     */
    function setCollateralVault(
        address _collateralVault
    ) public override onlyRole(_ADMIN_) {
        super._setCollateralVault(_collateralVault);
    }

    /**
     * Updates the loan state and times.
     *
     * This funcion conducts updates per the following conditions:
     *  > If the loan is in an expired state, the loan times are updated and
     *    the loan state is set to _DEFAULT_STATE_.
     *  > If the loan is fully paid off, the loan state is set to _PAID_STATE_.
     *  > If the loan is active and interest is accruing, the loan times are
     *    updated.
     *  > If the loan is currently in _ACTIVE_GRACE_STATE_ and the grace period
     *    has expired, the loan state is transitioned to _ACTIVE_STATE_ and the
     *    loan times are updated.
     *
     * @param _debtId The debt id.
     *
     * @dev This function is only callable by the _TREASURER_ role.
     * @dev This function is only callable when the loan is active or closed
     * (i.e. not in an inactive state).
     *
     * @return True if the loan remains active, false otherwise.
     */
    function updateLoanState(
        uint256 _debtId
    ) external onlyRole(_TREASURER_) returns (uint256) {
        if (checkLoanClosed(_debtId)) {
            console.log("Closed loan: %s", _debtId);
            return _UINT256_MAX_;
        }

        if (!checkLoanActive(_debtId)) {
            console.log("Inactive loan: %s", _debtId);
            revert StdCodecErrors.InactiveLoanState();
        }

        // Loan defaulted
        if (checkLoanExpired(_debtId)) {
            console.log("Defaulted loan: %s", _debtId);
            _updateLoanTimes(_debtId, 4);
            _updateLoanState(_debtId, _DEFAULT_STATE_);
            return 4;
        }
        // Loan fully paid off
        else if (debtBalance(_debtId) <= 0) {
            console.log("Paid loan: %s", _debtId);
            _updateLoanState(_debtId, _PAID_STATE_);
            return 3;
        }
        // Loan active and interest compounding
        else if (loanState(_debtId) == _ACTIVE_STATE_) {
            console.log("Active loan: %s", _debtId);
            _updateLoanTimes(_debtId, 2);
            return 2;
        }
        // Loan no longer in grace period
        else if (!_checkLoanGracePeriod(_debtId)) {
            console.log("Grace period expired: %s", _debtId);
            _updateLoanState(_debtId, _ACTIVE_STATE_);
            _updateLoanTimes(_debtId, 2);
            return 2;
        } else if (_checkLoanGracePeriod(_debtId)) {
            console.log("Grace period ongoing: %s", _debtId);
            return 1;
        }

        return 0;
    }

    function verifyLoanActive(uint256 _debtId) public view {
        if (!checkLoanActive(_debtId))
            revert StdCodecErrors.InactiveLoanState();
    }

    function verifyLoanNotExpired(uint256 _debtId) public view {
        if (checkLoanExpired(_debtId)) revert StdCodecErrors.ExpriredLoan();
    }

    function checkProposalActive(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce
    ) public view returns (bool) {
        uint256 _nextCollateralNonce = collateralNonce(
            _collateralAddress,
            _collateralId
        );

        return _nextCollateralNonce <= _collateralNonce;
    }

    function checkLoanActive(uint256 _debtId) public view returns (bool) {
        return
            loanState(_debtId) >= _ACTIVE_GRACE_STATE_ &&
            loanState(_debtId) <= _ACTIVE_STATE_;
    }

    function checkLoanDefault(uint256 _debtId) public view returns (bool) {
        return
            loanState(_debtId) >= _DEFAULT_STATE_ &&
            loanState(_debtId) <= _AWARDED_STATE_;
    }

    function checkLoanClosed(uint256 _debtId) public view returns (bool) {
        return loanState(_debtId) >= _PAID_PENDING_STATE_;
    }

    function checkLoanExpired(uint256 _debtId) public view returns (bool) {
        return
            debtBalance(_debtId) > 0 && loanClose(_debtId) <= block.timestamp;
    }

    function _checkLoanGracePeriod(
        uint256 _debtId
    ) internal view returns (bool) {
        return loanStart(_debtId) > block.timestamp;
    }
}

/* ------------------------------------------------ *
 *           EIP712 Domain Type Hashes              *
 * ------------------------------------------------ */
bytes32 constant _TYPE_HASH_ = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

/* ------------------------------------------------ *
 *           Loan Contract Type Hashes              *
 * ------------------------------------------------ */
bytes32 constant _CONTRACT_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "ContractParams(uint256 principal,bytes32 contractTerms,address collateralAddress,uint256 collateralId,uint256 collateralNonce)"
);

/* ------------------------------------------------ *
 *        Anza Debt Storefront Type Hashes          *
 * ------------------------------------------------ */
bytes32 constant _DEBT_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "DebtParams(uint256 price,address collateralAddress,uint256 collateralId,uint256 listingNonce,uint256 termsExpiry)"
);
bytes32 constant _SPONSORSHIP_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "SponsorshipParams(uint256 price,uint256 debtId,uint256 listingNonce,uint256 termsExpiry)"
);
bytes32 constant _REFINANCE_PARAMS_ENCODE_TYPE_HASH_ = keccak256(
    "RefinanceParams(uint256 price,uint256 debtId,bytes32 contractTerms,uint256 listingNonce,uint256 termsExpiry)"
);

/* ------------------------------------------------ *
 *         Manager Custom Error Selectors           *
 * ------------------------------------------------ */
bytes4 constant _INVALID_SIGNER_SELECTOR_ = 0x815e1d64; // bytes4(keccak256("InvalidSigner()"))

library StdNotaryErrors {
    /* ------------------------------------------------ *
     *                 Notary Errors                    *
     * ------------------------------------------------ */
    error InvalidSigner();
    error InvalidOwnerMethod();
    error InvalidSignatureLength();
}

interface ILoanNotary {
    struct ContractParams {
        uint256 principal;
        bytes32 contractTerms;
        address collateralAddress;
        uint256 collateralId;
        uint256 collateralNonce;
    }
}

interface IDebtNotary {
    struct DebtParams {
        uint256 price;
        address collateralAddress;
        uint256 collateralId;
        uint256 listingNonce;
        uint256 termsExpiry;
    }
}

interface ISponsorshipNotary {
    struct SponsorshipParams {
        uint256 price;
        uint256 debtId;
        uint256 listingNonce;
        uint256 termsExpiry;
    }
}

interface IRefinanceNotary {
    struct RefinanceParams {
        uint256 price;
        uint256 debtId;
        uint256 listingNonce;
        uint256 termsExpiry;
        bytes32 contractTerms;
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

/**
 * @title AnzaNotary
 * @author jjgarcia.eth
 * @notice The AnzaNotary library provides functions to recovery and validate
 * debt transaction signatures.
 *
 * @dev This library is an interface for using the EIP-1271 standard for
 * signature validation. Currently, this library supports debt transaction
 * signature validation for initial Loan terms and Debt, Refinance, and
 * Sponsorship sales.
 *
 * See {LoanNotary:LoanNotary, LoanNotary:DebtNotary,
 * LoanNotary:RefinanceNotary, LoanNotary:SponsorshipNotary}.
 */
library AnzaNotary {
    struct DomainSeparator {
        string name;
        string version;
        uint256 chainId;
        address contractAddress;
    }

    function createContractTerms(
        uint8 _firInterval,
        uint8 _fixedInterestRate,
        uint8 _isFixed,
        uint8 _commital,
        uint32 _gracePeriod,
        uint32 _duration,
        uint32 _termsExpiry,
        uint8 _lenderRoyalties
    ) public pure returns (bytes32 _contractTerms) {
        assembly {
            mstore(0x20, _firInterval)
            mstore(0x1f, _fixedInterestRate)

            switch eq(_isFixed, 0x01)
            case true {
                mstore(0x1e, add(0x65, _commital))
            }
            case false {
                mstore(0x1e, _commital)
            }

            mstore(0x0d, _gracePeriod)
            mstore(0x09, _duration)
            mstore(0x05, _termsExpiry)
            mstore(0x01, _lenderRoyalties)

            _contractTerms := mload(0x20)
        }
    }

    /**
     * {see LoanNotary:LoanNotary-__recoverSigner}
     */
    function recoverSigner(
        ILoanNotary.ContractParams memory _contractParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(_contractParams, _domainSeparator);

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * {see LoanNotary:DebtNotary-__recoverSigner}
     */
    function recoverSigner(
        IDebtNotary.DebtParams memory _debtParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(_debtParams, _domainSeparator);

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * {see LoanNotary:RefinanceNotary-__recoverSigner}
     */
    function recoverSigner(
        address _anzaTokenAddress,
        IRefinanceNotary.RefinanceParams memory _refinanceParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(
            _anzaTokenAddress,
            _refinanceParams,
            _domainSeparator
        );

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * {see LoanNotary:SponsorshipNotary-__recoverSigner}
     */
    function recoverSigner(
        address _anzaTokenAddress,
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams,
        DomainSeparator memory _domainSeparator,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = typeDataHash(
            _anzaTokenAddress,
            _sponsorshipParams,
            _domainSeparator
        );

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * {see LoanNotary:LoanNotary-__domainSeparator}
     */
    function domainSeparator(
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH_,
                    keccak256(abi.encodePacked(_domainSeparator.name)),
                    keccak256(abi.encodePacked(_domainSeparator.version)),
                    _domainSeparator.chainId,
                    _domainSeparator.contractAddress
                )
            );
    }

    /**
     * {see LoanNotary:LoanNotary-__typeDataHash}
     */
    function typeDataHash(
        ILoanNotary.ContractParams memory _contractParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_contractParams)
                )
            );
    }

    /**
     * {see LoanNotary:DebtNotary-__typeDataHash}
     */
    function typeDataHash(
        IDebtNotary.DebtParams memory _debtParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_debtParams)
                )
            );
    }

    /**
     * {see LoanNotary:RefinanceNotary-__typeDataHash}
     */
    function typeDataHash(
        address _anzaTokenAddress,
        IRefinanceNotary.RefinanceParams memory _refinanceParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_anzaTokenAddress, _refinanceParams)
                )
            );
    }

    /**
     * {see LoanNotary:SponsorshipNotary-__typeDataHash}
     */
    function typeDataHash(
        address _anzaTokenAddress,
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams,
        DomainSeparator memory _domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(_domainSeparator),
                    structHash(_anzaTokenAddress, _sponsorshipParams)
                )
            );
    }

    function structHash(
        ILoanNotary.ContractParams memory _contractParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _CONTRACT_PARAMS_ENCODE_TYPE_HASH_,
                    _contractParams.principal,
                    _contractParams.contractTerms,
                    _contractParams.collateralAddress,
                    _contractParams.collateralId,
                    _contractParams.collateralNonce
                )
            );
    }

    function structHash(
        IDebtNotary.DebtParams memory _debtParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DEBT_PARAMS_ENCODE_TYPE_HASH_,
                    _debtParams.price,
                    _debtParams.collateralAddress,
                    _debtParams.collateralId,
                    _debtParams.listingNonce,
                    _debtParams.termsExpiry
                )
            );
    }

    function structHash(
        address _anzaTokenAddress,
        IRefinanceNotary.RefinanceParams memory _refinanceParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _REFINANCE_PARAMS_ENCODE_TYPE_HASH_,
                    _refinanceParams.price,
                    _anzaTokenAddress,
                    _refinanceParams.debtId,
                    _refinanceParams.contractTerms,
                    _refinanceParams.listingNonce,
                    _refinanceParams.termsExpiry
                )
            );
    }

    function structHash(
        address _anzaTokenAddress,
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _SPONSORSHIP_PARAMS_ENCODE_TYPE_HASH_,
                    _sponsorshipParams.price,
                    _anzaTokenAddress,
                    _sponsorshipParams.debtId,
                    _sponsorshipParams.listingNonce,
                    _sponsorshipParams.termsExpiry
                )
            );
    }

    function splitSignature(
        bytes memory _signature
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (_signature.length != 65)
            revert StdNotaryErrors.InvalidSignatureLength();

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }
}

/**
 * @title LoanNotary
 * @author jjgarcia.eth
 */

/**
 * @notice This contract implements the EIP 1271 type-specific encoding of signed loan contract
 * terms.
 */
abstract contract LoanNotary is ILoanNotary {
    /**
     * This hashed value is used to prevent replay attacks from malicious actors
     * attempting to use a signed message to execute the same action multiple
     * times.
     */
    bytes32 private immutable __loanNotary_domainSeparator;

    constructor(string memory _contractName, string memory _contractVersion) {
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __loanNotary_domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH_,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(ILoanNotary).interfaceId;
    }

    /**
     * @dev Returns the verified borrower of a signed set of loan contract
     * terms.
     *
     * @param _contractParams the loan contract terms.
     * @param _borrowerSignature the signed loan contract terms.
     * @param ownerOf the function used to identify the recorded borrower. If
     * this is called as an original loan contract for a new loan, this should
     * be a IERC721.ownerOf call on the collateral contract. If this is called
     * as a loan contract refinance for existing debt, this should be a
     * IAnzaToken.borrowerOf call on the debt contract.
     *
     * @return the verified borrower of the loan contract.
     */
    function _getBorrower(
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        if (_contractParams.collateralAddress != ownerOf.address)
            revert StdNotaryErrors.InvalidOwnerMethod();

        address _borrower = ownerOf(_contractParams.collateralId);

        if (
            _borrower == msg.sender ||
            _borrower != _recoverSigner(_contractParams, _borrowerSignature)
        ) revert StdNotaryErrors.InvalidSigner();

        return _borrower;
    }

    /**
     * Verifies the sender is the owner of the collateral and borrower of a signed
     * set of loan contract terms.
     *
     * @param _contractParams the loan contract terms.
     * @param _borrowerSignature the signed loan contract terms.
     * @param ownerOf the function used to identify the recorded borrower. If
     * this is called as an original loan contract for a new loan, this should
     * be a IERC721.ownerOf call on the collateral contract. If this is called
     * as a loan contract refinance for existing debt, this should be a
     * IAnzaToken.borrowerOf call on the debt contract.
     *
     * @return the address of the borrower.
     */
    function _verifyBorrower(
        ContractParams memory _contractParams,
        bytes memory _borrowerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        if (_contractParams.collateralAddress != ownerOf.address)
            revert StdNotaryErrors.InvalidOwnerMethod();

        address _borrower = ownerOf(_contractParams.collateralId);

        if (
            _borrower != msg.sender ||
            _borrower != _recoverSigner(_contractParams, _borrowerSignature)
        ) revert StdNotaryErrors.InvalidSigner();

        return _borrower;
    }

    /**
     * Returns the address that signed a hashed message (`hash`) with `_signature`.
     * This address can then be used for verification purposes.
     *
     * @param _contractParams the loan contract terms.
     * @param _signature the signed loan contract terms.
     *
     * {see ECDSA-recover}
     *
     * @return the address that signed the message.
     */
    function _recoverSigner(
        ContractParams memory _contractParams,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 _message = __typeDataHash(_contractParams);

        (uint8 v, bytes32 r, bytes32 s) = AnzaNotary.splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * Returns an Ethereum Signed Typed Data, created from a `domainSeparator`
     * and a `structHash`. This produces hash corresponding to the one signed.
     *
     * @param _contractParams the loan contract terms.
     *
     * {see EIP-712}
     *
     * @return the hash of the structured message.
     */
    function __typeDataHash(
        ContractParams memory _contractParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    __loanNotary_domainSeparator,
                    __structHash(_contractParams)
                )
            );
    }

    /**
     * Returns the hash of a structured message. This hash shall be combined with
     * the `domainSeparator` and signed by the signer using their private key to
     * produce a signature. The signature is then used to verify that the structured
     * message originated from the signer.
     *
     * @param _contractParams the loan contract terms.
     *
     * {see EIP-712}
     *
     * @return the hash of the structured message.
     */
    function __structHash(
        ContractParams memory _contractParams
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _CONTRACT_PARAMS_ENCODE_TYPE_HASH_,
                    _contractParams.principal,
                    _contractParams.contractTerms,
                    _contractParams.collateralAddress,
                    _contractParams.collateralId,
                    _contractParams.collateralNonce
                )
            );
    }
}

/**
 * @notice This contract implements the EIP 1271 type-specific encoding of signed
 * debt sales terms.
 */
abstract contract DebtNotary is IDebtNotary {
    /**
     * This hashed value is used to prevent replay attacks from malicious actors
     * attempting to use a signed message to execute the same action multiple times.
     */
    bytes32 private immutable __debtNotary_domainSeparator;
    address private immutable __debtNotary_anzaTokenAddress;

    constructor(
        string memory _contractName,
        string memory _contractVersion,
        address _anzaTokenAddress
    ) {
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __debtNotary_domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH_,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );

        __debtNotary_anzaTokenAddress = _anzaTokenAddress;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IDebtNotary).interfaceId;
    }

    /**
     * @dev Returns the verified signer of a signed set of loan contract terms.
     *
     * @param _assetId the debt ID of the asset.
     * @param _debtParams the debt terms.
     * @param _sellerSignature the signed debt listing terms.
     * @param ownerOf the function used to identify the recorded borrower.
     *
     * @return the address of the signer.
     */
    function _getSigner(
        uint256 _assetId,
        DebtParams memory _debtParams,
        bytes memory _sellerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        if (__debtNotary_anzaTokenAddress != ownerOf.address)
            revert StdNotaryErrors.InvalidOwnerMethod();

        address _seller = ownerOf(_assetId);

        if (
            _seller == msg.sender ||
            _seller != _recoverSigner(_debtParams, _sellerSignature)
        ) revert StdNotaryErrors.InvalidSigner();

        return _seller;
    }

    /**
     * Returns the address that signed a hashed message (`hash`) with `_signature`.
     * This address can then be used for verification purposes.
     *
     * @param _debtParams the debt terms.
     * @param _signature the signed debt listing terms.
     *
     * {see ECDSA-recover}
     *
     * @return the address of the signer.
     */
    function _recoverSigner(
        DebtParams memory _debtParams,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 _message = __typeDataHash(_debtParams);

        (uint8 v, bytes32 r, bytes32 s) = AnzaNotary.splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * Returns an Ethereum Signed Typed Data, created from a `domainSeparator`
     * and a `structHash`. This produces hash corresponding to the one signed.
     *
     * @param _debtParams the debt terms.
     *
     * {see EIP1271}
     *
     * @return the hash of the structured message.
     */
    function __typeDataHash(
        DebtParams memory _debtParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    __debtNotary_domainSeparator,
                    __structHash(_debtParams)
                )
            );
    }

    /**
     * Returns the hash of a structured message. This hash shall be
     * combined with the `domainSeparator` and signed by the signer using their
     * private key to produce a signature. The signature is then used to verify
     * that the structured message originated
     * from the signer.
     *
     * @param _debtParams the debt terms.
     *
     * {see EIP1271}
     *
     * @return the hash of the structured message.
     */
    function __structHash(
        DebtParams memory _debtParams
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DEBT_PARAMS_ENCODE_TYPE_HASH_,
                    _debtParams.price,
                    _debtParams.collateralAddress,
                    _debtParams.collateralId,
                    _debtParams.listingNonce,
                    _debtParams.termsExpiry
                )
            );
    }
}

/**
 * @notice This contract implements the EIP 1271 type-specific encoding of signed debt refinance
 * sales terms.
 */
abstract contract RefinanceNotary is IRefinanceNotary {
    /**
     * Returns the value that is unique to each contract that uses EIP-1271.
     * This hashed value is used to prevent replay attacks from malicious actors
     * attempting to use a signed message to execute the same action multiple
     * times.
     */
    bytes32 private immutable __refinanceNotary_domainSeparator;
    address private immutable __refinanceNotary_anzaTokenAddress;

    constructor(
        string memory _contractName,
        string memory _contractVersion,
        address _anzaTokenAddress
    ) {
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __refinanceNotary_domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH_,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );

        __refinanceNotary_anzaTokenAddress = _anzaTokenAddress;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(IRefinanceNotary).interfaceId;
    }

    /**
     * Returns the verified borrower of a signed set of loan contract
     * terms.
     *
     * @param _refinanceParams The debt refinance listing terms.
     * @param _sellerSignature The signed debt refinance listing terms.
     * @param ownerOf The function used to identify the recorded borrower.
     *
     * @return The address of the borrower.
     */
    function _getBorrower(
        RefinanceParams memory _refinanceParams,
        bytes memory _sellerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        if (__refinanceNotary_anzaTokenAddress != ownerOf.address)
            revert StdNotaryErrors.InvalidOwnerMethod();

        address _borrower = ownerOf(_refinanceParams.debtId);

        if (
            _borrower == msg.sender ||
            _borrower != _recoverSigner(_refinanceParams, _sellerSignature)
        ) revert StdNotaryErrors.InvalidSigner();

        return _borrower;
    }

    /**
     * Returns the address that signed a hashed message (`hash`) with
     * `_signature`. This address can then be used for verification purposes.
     *
     * @param _refinanceParams The debt refinance listing terms.
     *
     * {see ECDSA-recover}
     *
     * @return The address of the signer.
     */
    function _recoverSigner(
        RefinanceParams memory _refinanceParams,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 _message = __typeDataHash(_refinanceParams);

        (uint8 v, bytes32 r, bytes32 s) = AnzaNotary.splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed.
     *
     * @param _refinanceParams The debt refinance listing terms.
     *
     * {see EIP1271}
     *
     * @return The hash of a structured message.
     */
    function __typeDataHash(
        RefinanceParams memory _refinanceParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    __refinanceNotary_domainSeparator,
                    __structHash(_refinanceParams)
                )
            );
    }

    /**
     * Returns the hash of a structured message. This hash shall be
     * combined with the `domainSeparator` and signed by the signer using their
     * private key to produce a signature. The signature is then used to verify
     * that the structured message originated
     * from the signer.
     *
     * @param _refinanceParams The debt refinance listing terms.
     *
     * {see EIP1271}
     *
     * @return The hash of a structured message.
     */
    function __structHash(
        RefinanceParams memory _refinanceParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _REFINANCE_PARAMS_ENCODE_TYPE_HASH_,
                    _refinanceParams.price,
                    __refinanceNotary_anzaTokenAddress,
                    _refinanceParams.debtId,
                    _refinanceParams.contractTerms,
                    _refinanceParams.listingNonce,
                    _refinanceParams.termsExpiry
                )
            );
    }
}

/**
 * @notice This contract implements the EIP 1271 type-specific encoding of signed debt sponsorship
 * sales terms.
 */
abstract contract SponsorshipNotary is ISponsorshipNotary {
    /**
     * This hashed value is used to prevent replay attacks from malicious actors
     * attempting to use a signed message to execute the same action multiple
     * times.
     */
    bytes32 private immutable __sponsorshipNotary_domainSeparator;
    address private immutable __sponsorshipNotary_anzaTokenAddress;

    constructor(
        string memory _contractName,
        string memory _contractVersion,
        address _anzaTokenAddress
    ) {
        bytes32 nameHash = keccak256(abi.encodePacked(_contractName));
        bytes32 versionHash = keccak256(abi.encodePacked(_contractVersion));

        __sponsorshipNotary_domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH_,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );

        __sponsorshipNotary_anzaTokenAddress = _anzaTokenAddress;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual returns (bool) {
        return _interfaceId == type(ISponsorshipNotary).interfaceId;
    }

    /**
     * Returns the verified signer of a signed set of loan contract
     * terms.
     *
     * @param _sponsorshipParams the debt listing terms.
     * @param _sellerSignature the signed debt listing terms.
     * @param ownerOf the function used to identify the recorded borrower.
     *
     * @return the verified signer of the signed debt listing terms.
     */
    function _getSigner(
        SponsorshipParams memory _sponsorshipParams,
        bytes memory _sellerSignature,
        function(uint256) external view returns (address) ownerOf
    ) internal view returns (address) {
        if (__sponsorshipNotary_anzaTokenAddress != ownerOf.address)
            revert StdNotaryErrors.InvalidOwnerMethod();

        address _seller = ownerOf(_sponsorshipParams.debtId);

        if (
            _seller == msg.sender ||
            _seller != _recoverSigner(_sponsorshipParams, _sellerSignature)
        ) revert StdNotaryErrors.InvalidSigner();

        return _seller;
    }

    /**
     * Returns the address that signed a hashed message (`hash`) with
     * `_signature`. This address can then be used for verification purposes.
     *
     * @param _sponsorshipParams the debt listing terms.
     * @param _signature the signed debt listing terms.
     *
     * {see ECDSA-recover}
     *
     * @return the address of the signer.
     */
    function _recoverSigner(
        SponsorshipParams memory _sponsorshipParams,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 _message = __typeDataHash(_sponsorshipParams);

        (uint8 v, bytes32 r, bytes32 s) = AnzaNotary.splitSignature(_signature);

        return ECDSA.recover(_message, v, r, s);
    }

    /**
     * Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed.
     *
     * @param _sponsorshipParams the debt listing terms.
     *
     * {see EIP-1271}
     *
     * @return the hash of the structured message.
     */
    function __typeDataHash(
        SponsorshipParams memory _sponsorshipParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    __sponsorshipNotary_domainSeparator,
                    __structHash(_sponsorshipParams)
                )
            );
    }

    /**
     * Returns the hash of a structured message. This hash shall be
     * combined with the `domainSeparator` and signed by the signer using their
     * private key to produce a signature. The signature is then used to verify
     * that the structured message originated
     * from the signer.
     *
     * @param _sponsorshipParams the debt listing terms.
     *
     * {see EIP-1271}
     *
     * @return the hash of the structured message.
     */
    function __structHash(
        SponsorshipParams memory _sponsorshipParams
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _SPONSORSHIP_PARAMS_ENCODE_TYPE_HASH_,
                    _sponsorshipParams.price,
                    __sponsorshipNotary_anzaTokenAddress,
                    _sponsorshipParams.debtId,
                    _sponsorshipParams.listingNonce,
                    _sponsorshipParams.termsExpiry
                )
            );
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract LoanContract is ILoanContract, LoanManager, LoanNotary {
    using TypeUtils for uint256;

    constructor() LoanManager() LoanNotary("LoanContract", "0") {}

    /**
     * Returns the support status of an interface.
     *
     * @param _interfaceId The interface ID to check for support.
     *
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(LoanManager, LoanNotary) returns (bool) {
        return
            _interfaceId == type(ILoanContract).interfaceId ||
            LoanManager.supportsInterface(_interfaceId) ||
            LoanNotary.supportsInterface(_interfaceId);
    }

    /**
     * Initialize a loan contract for an uncollateralized ERC721 token.
     *
     * @param _collateralAddress The address of the ERC721 collateral token.
     * @param _collateralId The ID of the ERC721 collateral token.
     * @param _contractTerms The loan contract terms.
     * @param _borrowerSignature The borrower's signature of the loan contract
     * terms.
     *
     * @dev The `_contractTerms` parameter is a packed bytes32 array of the
     * following values:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   `isFixed` and `commital`
     *  > 008 - [20..27]   `loanCurrency`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     *
     * Emits a {LoanContractInitialized} event.
     */
    function initContract(
        address _collateralAddress,
        uint256 _collateralId,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) external payable {
        // Validate loan terms
        uint256 _principal = msg.value;
        _validateLoanTerms(
            _contractTerms,
            block.timestamp._toUint64(),
            _principal
        );

        // Set debt
        (, uint256 _collateralNonce) = _writeDebt(
            _collateralAddress,
            _collateralId
        );

        // Verify borrower participation
        IERC721Metadata _collateralToken = IERC721Metadata(_collateralAddress);

        address _borrower = _getBorrower(
            ContractParams({
                principal: _principal,
                contractTerms: _contractTerms,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            }),
            _borrowerSignature,
            _collateralToken.ownerOf
        );

        // Add debt to database
        __sealContract(block.timestamp._toUint64(), 1, _contractTerms);

        // The collateral ID and address will be mapped within
        // the loan collateral vault to the debt ID.
        _collateralToken.safeTransferFrom(
            _borrower,
            address(_collateralVault),
            _collateralId,
            abi.encodePacked(totalDebts)
        );

        // Transfer funds to borrower's account in treasurey
        (bool _success, ) = _loanTreasurerAddress.call{value: _principal}(
            abi.encodeWithSignature("depositFunds(address)", _borrower)
        );
        if (!_success) revert StdMonetaryErrors.FailedFundsTransfer();

        // Mint debt ADT for lender
        string memory _collateralURI = _collateralToken.tokenURI(_collateralId);

        _anzaToken.mint(
            msg.sender,
            totalDebts,
            _principal,
            _collateralURI,
            abi.encodePacked(_borrower)
        );

        // Emit initialization event
        emit ContractInitialized(
            _collateralAddress,
            _collateralId,
            totalDebts,
            1
        );
    }

    /**
     * Refinance fractions of debt with a new loan. This will alter and create
     * a new debt agreement for the collateralized ERC721 token.
     *
     * @dev The call stack of this function is:
     * > AnzaDebtStorefront:buyRefinance(uint256,uint256,{uint256},bytes)
     * > LoanTreasurey:executeRefinancePurchase(uint256,address,address,bytes32)
     *
     * @notice This function does not verify the loan contract with the
     * borrower. It should never be used to alter existing contract terms
     * and shall only be callable by the treasurer. It is required that the
     * treasurer verifies the loan contract with the borrower before calling
     * this function.
     *
     * @param _debtId The ID of the debt to refinance.
     * @param _borrower The address of the borrower.
     * @param _lender The address of the new lender.
     * @param _contractTerms The new loan contract terms.
     *
     * @dev The `_contractTerms` parameter is a packed bytes32 array of the
     * following values:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   unused space
     *  > 128 - [20..147]  `principal`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     *
     * Emits a {LoanContractRefinanced} event.
     */
    function initContract(
        uint256 _debtId,
        address _borrower,
        address _lender,
        bytes32 _contractTerms
    ) external payable onlyRole(_TREASURER_) {
        // Verify existing loan is in good standing
        if (checkLoanDefault(_debtId)) revert StdLoanErrors.InvalidCollateral();

        // Validate loan terms
        uint256 _principal = msg.value;
        _validateLoanTerms(
            _contractTerms,
            block.timestamp._toUint64(),
            _principal
        );

        // Get collateral from vault
        ICollateralVault.Collateral memory _collateral = _collateralVault
            .getCollateral(_debtId);

        // Set debt
        (uint256 _debtMapLength, ) = _appendDebt(
            _collateral.collateralAddress,
            _collateral.collateralId
        );

        // Add debt to database
        __sealContract(
            block.timestamp._toUint64(),
            _debtMapLength,
            _contractTerms
        );

        // Store collateral-debtId mapping in vault
        _collateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );

        // Replace or reduce previous debt. Any excess funds will
        // be available for withdrawal in the treasurey.
        (bool _success, ) = _loanTreasurerAddress.call{value: _principal}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _borrower,
                _debtId
            )
        );
        if (!_success) revert StdMonetaryErrors.FailedFundsTransfer();

        // Mint debt ADT for lender.
        _anzaToken.mint(
            _lender,
            totalDebts,
            _principal,
            abi.encode(address(_borrower), _debtId)
        );

        // Emit initialization event
        emit ContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );
    }

    /**
     * TODO: Revisit to check if we can't just transfer the debt tokens to the
     * new lender and transfer the payment directly to the previous lender's
     * withdrawable balance.
     *
     * Transfer debt to a new lender. This will not alter existing loan terms.
     *
     * @dev The call stack of this function is:
     * > AnzaDebtStorefront:buySponsorship(uint256,uint256,{uint256},bytes)
     * > LoanTreasurey:executeSponsorshipPurchase(uint256,address)
     *
     * @notice This function does not verify the loan contract with the
     * borrower. It should never be used to alter existing contract terms
     * and shall only be callable by the treasurer. It is required that the
     * treasurer verifies the loan contract with the borrower before calling
     * this function.
     *
     * @param _debtId The ID of the debt to refinance.
     * @param _borrower The address of the borrower.
     * @param _lender The address of the new lender.
     *
     * @dev The `_contractTerms` parameter is a packed bytes32 array of the
     * following values:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   unused space
     *  > 128 - [20..147]  `principal`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     *
     * Emits a {LoanContractRefinanced} event.
     */
    function initContract(
        uint256 _debtId,
        address _borrower,
        address _lender
    ) external payable onlyRole(_TREASURER_) {
        // Verify existing loan is in good standing
        if (checkLoanDefault(_debtId)) revert StdLoanErrors.InvalidCollateral();

        // Validate loan terms
        // Unnecessary since the terms are existing and have already been
        // validated.
        uint256 _principal = msg.value;

        // Get collateral from vault
        ICollateralVault.Collateral memory _collateral = _collateralVault
            .getCollateral(_debtId);

        // Set debt
        (uint256 _debtMapLength, ) = _appendDebt(
            _collateral.collateralAddress,
            _collateral.collateralId
        );

        // Add debt to database
        __sealContract(
            block.timestamp._toUint64(),
            _debtMapLength,
            debtTerms(_debtId)
        );

        // Store collateral-debtId mapping in vault
        _collateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );

        // Record balance for redistribution of debt.
        // @note: This is necessary since the debt will be reduced
        // by the sponsorPayment function.
        uint256 _balance = lenderDebtBalance(_debtId);

        // Replace or reduce previous debt. Any excess funds will
        // be available for withdrawal in the treasurey.
        (bool _success, ) = _loanTreasurerAddress.call{value: _principal}(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _borrower,
                _debtId
            )
        );
        if (!_success) revert StdMonetaryErrors.FailedFundsTransfer();

        // Mint debt ADT for lender.
        _anzaToken.mint(
            _lender,
            totalDebts,
            _principal >= _balance ? _balance : _principal,
            abi.encode(address(_borrower), _debtId)
        );

        // Emit initialization event
        emit ContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debtMapLength
        );
    }

    /**
     * Revoke a proposed loan contract.
     *
     * @dev This function will only revoke a proposed loan contract if the caller
     * is the borrower and the holder of the collateral and if the signed collateral
     * nonce is still active.
     *
     * @notice Revoking a proposed loan is performed by using the collateral nonce.
     * Therefore all other loan proposals for this collateral with the same nonce will
     * also be revoked and require a new offchain proposal.
     *
     * @param _collateralAddress The address of the collateral token.
     * @param _collateralId The ID of the collateral token.
     * @param _principal The principal amount of the loan.
     * @param _contractTerms The contract terms.
     * @param _borrowerSignature The borrower's signature.
     *
     * Emits a {ProposalRevoked} event.
     *
     * See {DebtBook._writeDebt} for more information.
     *
     * Returns a boolean indicating whether the proposal was revoked.
     */
    function revokeProposal(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _principal,
        bytes32 _contractTerms,
        bytes calldata _borrowerSignature
    ) external returns (bool) {
        // Revoke proposed debt
        (, uint256 _collateralNonce) = _writeDebt(
            _collateralAddress,
            _collateralId,
            type(uint256).max
        );

        // Verify borrower participation
        IERC721Metadata _collateralToken = IERC721Metadata(_collateralAddress);

        // If this fails, the whole transaction will revert.
        _verifyBorrower(
            ContractParams({
                principal: _principal,
                contractTerms: _contractTerms,
                collateralAddress: _collateralAddress,
                collateralId: _collateralId,
                collateralNonce: _collateralNonce
            }),
            _borrowerSignature,
            _collateralToken.ownerOf
        );

        // Emit revoke event
        emit ProposalRevoked(
            _collateralAddress,
            _collateralId,
            _collateralNonce,
            _contractTerms
        );

        return true;
    }

    /**
     * Seal a loan agreement between a borrower and lender.
     *
     * @dev This function is called by the initLoanContract functions when a loan
     * agreement is validated. Following the completion of this function, a new
     * deb will be added to the `__packedDebtTerms` mapping as specified within
     * LoanCodec.sol.
     *
     * @param _now The current timestamp.
     * @param _activeLoanIndex The index of the active loan.
     * @param _contractTerms The contract terms.
     *
     * @dev Reverts if the `_activeLoanIndex` exceeds the maximum refinances.
     */
    function __sealContract(
        uint64 _now,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) private {
        if (_activeLoanIndex > maxRefinances())
            revert StdMonetaryErrors.ExceededRefinanceLimit();

        _setLoanAgreement(_now, totalDebts, _activeLoanIndex, _contractTerms);
    }
}
