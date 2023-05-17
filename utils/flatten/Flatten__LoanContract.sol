/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(
                gas(),
                consoleAddress,
                payloadStart,
                payloadLength,
                0,
                0
            )
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256)", p0, p1)
        );
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address)", p0, p1)
        );
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
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

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
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

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256)", p0, p1)
        );
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address)", p0, p1)
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,address)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,string)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,address)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,string)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3)
        );
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
    function sqrt(
        uint256 a,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

////import "./math/Math.sol";

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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

interface ILoanTreasurey {
    error InvalidParticipant();
    error InvalidFundsTransfer();
    error InactiveLoanState();
    error InvalidLoanState();

    event Deposited(
        uint256 indexed debtId,
        address indexed payer,
        uint256 weiAmount
    );

    event Withdrawn(address indexed payee, uint256 weiAmount);

    function sponsorPayment(address _sponsor, uint256 _debtId) external payable;

    function depositPayment(uint256 _debtId) external payable;

    function withdrawFromBalance(uint256 _amount) external returns (bool);

    function withdrawCollateral(uint256 _debtId) external returns (bool);

    function executeDebtPurchase(
        uint256 _debtId,
        address _borrower,
        address _purchaser
    ) external payable returns (bool);

    function updateDebt(uint256 _debtId) external;
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAnzaToken is IAccessControl {
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

    function anzaTransferFrom(
        address _from,
        address _to,
        uint256 _debtId,
        bytes memory _data
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

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

    function checkBorrowerOf(
        address _account,
        uint256 _debtId
    ) external view returns (bool);

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
    /// @param _id ID of the token type
    /// @param _amount Transfer amount
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /// @param _debtId argument MUST be the debt ID for deriving token ID being transferred.
    /// @param _value argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    function mint(uint256 _debtId, uint256 _value) external;

    /// @param _to argument MUST be the address of the recipient whose balance is increased.
    /// @param _id argument MUST be the token ID being transferred.
    /// @param _value argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function mint(
        address _to,
        uint256 _id,
        uint256 _value,
        string calldata _collateralURI,
        bytes memory _data
    ) external;

    /// @param _account argument MUST be the address of the owner/operator whose balance is decreased.
    /// @param _id argument MUST be the token being burned.
    /// @param _value argument MUST be the number of tokens the holder balance is decreased by.
    function burn(address _account, uint256 _id, uint256 _value) external;

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _values
    ) external;

    function burnBorrowerToken(uint256 _debtId) external;
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        bytes32 role,
        address account
    ) public view virtual override returns (bool) {
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
    function getRoleAdmin(
        bytes32 role
    ) public view virtual override returns (bytes32) {
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
    function grantRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IAnzaToken.sol";
////import "./ILoanTreasurey.sol";

interface IManagerAccessController {
    function anzaToken() external returns (address);

    function loanTreasurer() external returns (address);

    function collateralVault() external returns (address);

    function setAnzaToken(address _anzaTokenAddress) external;

    function setLoanTreasurer(address _loanTreasurerAddress) external;

    function setCollateralVault(address _collateralVaultAddress) external;
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *              Loan Contract Roles                 *
 * ------------------------------------------------ */
bytes32 constant _ADMIN_ = keccak256("_ADMIN_");
bytes32 constant _LOAN_CONTRACT_ = keccak256("_LOAN_CONTRACT_");
bytes32 constant _TREASURER_ = keccak256("_TREASURER_");
bytes32 constant _COLLECTOR_ = keccak256("_COLLECTOR_");
bytes32 constant _DEBT_STOREFRONT_ = keccak256("_DEBT_STOREFRONT_");

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */
pragma solidity ^0.8.0;

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
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *           Packed Debt Term Mappings              *
 *-------------------------------------------*/
uint256 constant _LOAN_STATE_MASK_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0;
uint256 constant _LOAN_STATE_MAP_ = 0x000000000000000000000000000000000000000000000000000000000000000F;
uint256 constant _FIR_INTERVAL_MASK_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0F;
uint256 constant _FIR_INTERVAL_MAP_ = 0x00000000000000000000000000000000000000000000000000000000000000F0;
uint256 constant _FIR_MASK_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FF;
uint256 constant _FIR_MAP_ = 0x000000000000000000000000000000000000000000000000000000000000FF00;
uint256 constant _LOAN_START_MASK_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFF;
uint256 constant _LOAN_START_MAP_ = 0x0000000000000000000000000000000000000000000000000000FFFFFFFF0000;
uint256 constant _LOAN_DURATION_MASK_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFF;
uint256 constant _LOAN_DURATION_MAP_ = 0x00000000000000000000000000000000000000000000FFFFFFFF000000000000;
uint256 constant _IS_FIXED_MASK_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFF;
uint256 constant _IS_FIXED_MAP_ = 0x0000000000000000000000000000000000000000000F00000000000000000000;
uint256 constant _COMMITAL_MASK_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFF;
uint256 constant _COMMITAL_MAP_ = 0x00000000000000000000000000000000000000000FF000000000000000000000;
uint256 constant _LENDER_ROYALTIES_MASK_ = 0xFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
uint256 constant _LENDER_ROYALTIES_MAP_ = 0x00FF000000000000000000000000000000000000000000000000000000000000;
uint256 constant _LOAN_COUNT_MASK_ = 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
uint256 constant _LOAN_COUNT_MAP_ = 0xFF00000000000000000000000000000000000000000000000000000000000000;
uint256 constant _CLEANUP_MASK_ = 0xFFFF0000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFF;

uint8 constant _LOAN_STATE_POS_ = 0;
uint8 constant _FIR_INTERVAL_POS_ = 4;
uint8 constant _FIR_POS_ = 8;
uint8 constant _LOAN_START_POS_ = 16;
uint8 constant _LOAN_DURATION_POS_ = 48;
uint8 constant _IS_FIXED_POS_ = 80;
uint8 constant _COMMITAL_POS_ = 84;
uint8 constant _LENDER_ROYALTIES_POS_ = 240;
uint8 constant _LOAN_COUNT_POS_ = 248;

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

////import "../domain/LoanContractFIRIntervals.sol";
////import "../domain/LoanContractTermMaps.sol";

////import "../abdk-libraries-solidity/ABDKMath64x64.sol";

library LibLoanContractSigning {
    struct ContractTerms {
        uint256 firInterval;
        uint8 fixedInterestRate;
        uint8 isFixed;
        uint8 commital;
        uint128 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
        uint8 lenderRoyalties;
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

    function recoverSigner(
        uint256 _principal,
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _message = prefixed(
            keccak256(
                abi.encode(
                    _principal,
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }

    function hashMessage(
        uint256 _principal,
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _principal,
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
                )
            );
    }

    function prefixed(bytes32 _hash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function splitSignature(
        bytes memory _signature
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}

library LibLoanContractIndexer {
    function getBorrowerTokenId(uint256 _debtId) public pure returns (uint256) {
        return (2 * _debtId) + 1;
    }

    function getLenderTokenId(uint256 _debtId) public pure returns (uint256) {
        return (2 * _debtId);
    }
}

library LibLoanContractTerms {
    struct ContractTerms {
        uint256 loanState;
        uint256 firInterval;
        uint256 fixedInterestRate;
        uint256 loanStart;
        uint256 loanDuration;
        uint256 loanCommital;
        uint256 loanCommitalTime;
        uint256 loanClose;
        uint256 isFixed;
        uint256 lenderRoyalties;
        uint256 activeLoanCount;
    }

    function loanState(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanState) {
        uint8 __loanState;

        assembly {
            __loanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function firInterval(
        bytes32 _contractTerms
    ) public pure returns (uint256 _firInterval) {
        uint8 __firInterval;

        assembly {
            __firInterval := shr(
                _FIR_INTERVAL_POS_,
                and(_contractTerms, _FIR_INTERVAL_MAP_)
            )
        }

        unchecked {
            _firInterval = __firInterval;
        }
    }

    function fixedInterestRate(
        bytes32 _contractTerms
    ) public pure returns (uint256 _fixedInterestRate) {
        bytes32 __fixedInterestRate;

        assembly {
            __fixedInterestRate := shr(
                _FIR_POS_,
                and(_contractTerms, _FIR_MAP_)
            )
        }

        unchecked {
            _fixedInterestRate = uint256(__fixedInterestRate);
        }
    }

    function loanLastChecked(
        bytes32 _contractTerms
    ) external pure returns (uint256) {
        return loanStart(_contractTerms);
    }

    function loanStart(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanStart) {
        uint32 __loanStart;

        assembly {
            __loanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )
        }

        unchecked {
            _loanStart = __loanStart;
        }
    }

    function loanDuration(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanDuration) {
        uint32 __loanDuration;

        assembly {
            __loanDuration := shr(
                _LOAN_DURATION_POS_,
                and(_contractTerms, _LOAN_DURATION_MAP_)
            )
        }

        unchecked {
            _loanDuration = __loanDuration;
        }
    }

    function loanCommital(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanCommital) {
        uint32 __loanCommital;

        assembly {
            __loanCommital := shr(
                _COMMITAL_POS_,
                and(_contractTerms, _COMMITAL_MAP_)
            )
        }

        unchecked {
            _loanCommital = __loanCommital;
        }
    }

    function loanCommitalTime(
        bytes32 _contractTerms
    ) public pure returns (uint256) {
        int128 _loanStart = ABDKMath64x64.fromUInt(loanStart(_contractTerms));
        int128 _loanDuration = ABDKMath64x64.fromUInt(
            loanDuration(_contractTerms)
        );
        int128 _ratio = ABDKMath64x64.divu(loanCommital(_contractTerms), 100);
        int128 _commitalPeriod = ABDKMath64x64.mul(_loanDuration, _ratio);
        int128 _commitalTime = ABDKMath64x64.add(_loanStart, _commitalPeriod);

        return ABDKMath64x64.toUInt(_commitalTime);
    }

    function isFixed(
        bytes32 _contractTerms
    ) public pure returns (uint256 _isFixed) {
        uint32 __isFixed;

        assembly {
            __isFixed := shr(
                _IS_FIXED_POS_,
                and(_contractTerms, _IS_FIXED_MAP_)
            )
        }

        unchecked {
            _isFixed = __isFixed;
        }
    }

    function loanClose(
        bytes32 _contractTerms
    ) public pure returns (uint256 _loanClose) {
        uint32 __loanClose;

        assembly {
            __loanClose := add(
                shr(_LOAN_START_POS_, and(_contractTerms, _LOAN_START_MAP_)),
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function lenderRoyalties(
        bytes32 _contractTerms
    ) public pure returns (uint256 _lenderRoyalties) {
        assembly {
            _lenderRoyalties := shr(
                _LENDER_ROYALTIES_POS_,
                and(_contractTerms, _LENDER_ROYALTIES_MAP_)
            )
        }
    }

    function activeLoanCount(
        bytes32 _contractTerms
    ) public pure returns (uint256 _activeLoanCount) {
        uint8 __activeLoanCount;

        assembly {
            __activeLoanCount := shr(
                _LOAN_COUNT_POS_,
                and(_contractTerms, _LOAN_COUNT_MAP_)
            )
        }

        unchecked {
            _activeLoanCount = __activeLoanCount;
        }
    }
}

library LibLoanContractInterest {
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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface ILoanCodec {
    error InactiveLoanState();
    error InvalidLoanParameter(bytes4 parameter);

    function getDebtTerms(uint256 _debtId) external view returns (bytes32);

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

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) external view returns (uint256);
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *                  Loan States                     *
 * ------------------------------------------------ */
uint8 constant _UNDEFINED_STATE_ = 0;
uint8 constant _NONLEVERAGED_STATE_ = 1;
uint8 constant _UNSPONSORED_STATE_ = 2;
uint8 constant _SPONSORED_STATE_ = 3;
uint8 constant _FUNDED_STATE_ = 4;
uint8 constant _ACTIVE_GRACE_STATE_ = 5;
uint8 constant _ACTIVE_STATE_ = 6;
uint8 constant _DEFAULT_STATE_ = 7;
uint8 constant _COLLECTION_STATE_ = 8;
uint8 constant _AUCTION_STATE_ = 9;
uint8 constant _AWARDED_STATE_ = 10;
uint8 constant _PAID_PENDING_STATE_ = 11;
uint8 constant _CLOSE_STATE_ = 12;
uint8 constant _PAID_STATE_ = 13;
uint8 constant _CLOSE_DEFAULT_STATE_ = 14;

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *                 Contract Numbers                 *
 * ------------------------------------------------ */
uint256 constant _SECONDS_PER_24_MINUTES_RATIO_SCALED_ = 1440;
uint256 constant _UINT32_MAX_ = 4294967295;

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

/* ------------------------------------------------ *
 *           Loan Term Standard Errors              *
 * ------------------------------------------------ */
bytes4 constant _LOAN_STATE_ERROR_ID_ = 0xdacce9d3;
bytes4 constant _FIR_INTERVAL_ERROR_ID_ = 0xa13e8948;
bytes4 constant _DURATION_ERROR_ID_ = 0xfcbf8511;
bytes4 constant _PRINCIPAL_ERROR_ID_ = 0x6a901435;
bytes4 constant _FIXED_INTEREST_RATE_ERROR_ID_ = 0x8fe03ac3;
bytes4 constant _GRACE_PERIOD_ERROR_ID_ = 0xb677e65e;
bytes4 constant _TIME_EXPIRY_ERROR_ID_ = 0x67b21a5c;
bytes4 constant _LENDER_ROYALTIES_ERROR_ID_ = 0xecc752dd;

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

////import "hardhat/console.sol";

////import "../domain/LoanContractRoles.sol";

////import "../interfaces/IManagerAccessController.sol";
////import "@openzeppelin/contracts/access/AccessControl.sol";

contract ManagerAccessController is IManagerAccessController, AccessControl {
    address internal _collateralVault;
    address internal _loanTreasurer;

    IAnzaToken internal _anzaToken;

    constructor() {
        _setRoleAdmin(_ADMIN_, _ADMIN_);
        _setRoleAdmin(_TREASURER_, _ADMIN_);

        _grantRole(_ADMIN_, msg.sender);
    }

    function anzaToken() external view returns (address) {
        return address(_anzaToken);
    }

    function loanTreasurer() external view returns (address) {
        return _loanTreasurer;
    }

    function collateralVault() external view returns (address) {
        return _collateralVault;
    }

    function setAnzaToken(
        address _anzaTokenAddress
    ) external onlyRole(_ADMIN_) {
        _anzaToken = IAnzaToken(_anzaTokenAddress);
    }

    function setLoanTreasurer(
        address _loanTreasurerAddress
    ) external onlyRole(_ADMIN_) {
        __setLoanTreasurer(_loanTreasurerAddress);
    }

    function setCollateralVault(
        address _collateralVaultAddress
    ) external onlyRole(_ADMIN_) {
        _collateralVault = _collateralVaultAddress;
    }

    function _grantRole(
        bytes32 _role,
        address _account
    ) internal virtual override {
        (_role == _TREASURER_)
            ? __setLoanTreasurer(_account)
            : super._grantRole(_role, _account);
    }

    function __setLoanTreasurer(address _loanTreasurerAddress) private {
        _revokeRole(_TREASURER_, _loanTreasurer);
        super._grantRole(_TREASURER_, _loanTreasurerAddress);

        _loanTreasurer = _loanTreasurerAddress;
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

////import "hardhat/console.sol";

////import "./domain/LoanContractErrorCodes.sol";
////import "./domain/LoanContractFIRIntervals.sol";
////import "./domain/LoanContractNumbers.sol";
////import "./domain/LoanContractTermMaps.sol";
////import "./domain/LoanContractStates.sol";

////import "./interfaces/ILoanCodec.sol";
////import {LibLoanContractInterest as Interest} from "./libraries/LibLoanContract.sol";

abstract contract LoanCodec is ILoanCodec {
    event LoanStateChanged(
        uint256 indexed debtId,
        uint8 indexed newLoanState,
        uint8 indexed oldLoanState
    );

    /**
     *  > 004 - [0..3]     `loanState`
     *  > 004 - [4..7]     `firInterval`
     *  > 008 - [8..15]    `fixedInterestRate`
     *  > 032 - [16..47]   `loanStart`
     *  > 032 - [48..79]   `loanDuration`
     *  > 160 - [80..239]  unused space
     *  > 008 - [240..247] `lenderRoyalties`
     *  > 008 - [248..255] `activeLoanIndex`
     */
    mapping(uint256 => bytes32) private __packedDebtTerms;

    function getDebtTerms(uint256 _debtId) external view returns (bytes32) {
        return __packedDebtTerms[_debtId];
    }

    function loanState(
        uint256 _debtId
    ) public view returns (uint256 _loanState) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __loanState;

        assembly {
            __loanState := and(_contractTerms, _LOAN_STATE_MAP_)
        }

        unchecked {
            _loanState = __loanState;
        }
    }

    function firInterval(
        uint256 _debtId
    ) public view returns (uint256 _firInterval) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __firInterval;

        assembly {
            __firInterval := shr(
                _FIR_INTERVAL_POS_,
                and(_contractTerms, _FIR_INTERVAL_MAP_)
            )
        }

        unchecked {
            _firInterval = __firInterval;
        }
    }

    function fixedInterestRate(
        uint256 _debtId
    ) public view returns (uint256 _fixedInterestRate) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        bytes32 __fixedInterestRate;

        assembly {
            __fixedInterestRate := shr(
                _FIR_POS_,
                and(_contractTerms, _FIR_MAP_)
            )
        }

        unchecked {
            _fixedInterestRate = uint256(__fixedInterestRate);
        }
    }

    function isFixed(uint256 _debtId) public view returns (uint256 _isFixed) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __isFixed;

        assembly {
            __isFixed := shr(
                _IS_FIXED_POS_,
                and(_contractTerms, _IS_FIXED_MAP_)
            )
        }

        unchecked {
            _isFixed = __isFixed;
        }
    }

    function loanLastChecked(uint256 _debtId) external view returns (uint256) {
        return loanStart(_debtId);
    }

    function loanStart(
        uint256 _debtId
    ) public view returns (uint256 _loanStart) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanStart;

        assembly {
            __loanStart := shr(
                _LOAN_START_POS_,
                and(_contractTerms, _LOAN_START_MAP_)
            )
        }

        unchecked {
            _loanStart = __loanStart;
        }
    }

    function loanDuration(
        uint256 _debtId
    ) public view returns (uint256 _loanDuration) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanDuration;

        assembly {
            __loanDuration := shr(
                _LOAN_DURATION_POS_,
                and(_contractTerms, _LOAN_DURATION_MAP_)
            )
        }

        unchecked {
            _loanDuration = __loanDuration;
        }
    }

    function loanCommital(
        uint256 _debtId
    ) public view returns (uint256 _loanCommital) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanCommital;

        assembly {
            __loanCommital := shr(
                _COMMITAL_POS_,
                and(_contractTerms, _COMMITAL_MAP_)
            )
        }

        unchecked {
            _loanCommital = __loanCommital;
        }
    }

    function loanClose(
        uint256 _debtId
    ) public view returns (uint256 _loanClose) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint32 __loanClose;

        assembly {
            __loanClose := add(
                shr(_LOAN_START_POS_, and(_contractTerms, _LOAN_START_MAP_)),
                shr(
                    _LOAN_DURATION_POS_,
                    and(_contractTerms, _LOAN_DURATION_MAP_)
                )
            )
        }

        unchecked {
            _loanClose = __loanClose;
        }
    }

    function lenderRoyalties(
        uint256 _debtId
    ) public view returns (uint256 _lenderRoyalties) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];

        assembly {
            _lenderRoyalties := shr(
                _LENDER_ROYALTIES_POS_,
                and(_contractTerms, _LENDER_ROYALTIES_MAP_)
            )
        }
    }

    function activeLoanCount(
        uint256 _debtId
    ) public view returns (uint256 _activeLoanCount) {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 __activeLoanCount;

        assembly {
            __activeLoanCount := shr(
                _LOAN_COUNT_POS_,
                and(_contractTerms, _LOAN_COUNT_MAP_)
            )
        }

        unchecked {
            _activeLoanCount = __activeLoanCount;
        }
    }

    function totalFirIntervals(
        uint256 _debtId,
        uint256 _seconds
    ) public view returns (uint256) {
        uint256 _firInterval = firInterval(_debtId);
        uint256 _duration = loanDuration(_debtId);
        _seconds = _seconds <= _duration ? _seconds : _duration;

        return _getTotalFirIntervals(_firInterval, _seconds);
    }

    function _validateLoanTerms(
        bytes32 _contractTerms,
        uint32 _loanStart,
        uint256 _principal
    ) internal view {
        uint8 _lenderRoyalties;
        uint32 _termsExpiry;
        uint32 _duration;
        uint32 _gracePeriod;
        uint8 _fixedInterestRate;
        uint8 _firInterval;

        assembly {
            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            _lenderRoyalties := mload(0)

            // Get packed terms expiry
            mstore(0x1b, _contractTerms)
            _termsExpiry := mload(0)

            // Get packed duration
            mstore(0x17, _contractTerms)
            _duration := mload(0)

            // Get packed grace period
            mstore(0x13, _contractTerms)
            _gracePeriod := mload(0)

            // Get fixed interest rate
            mstore(0x01, _contractTerms)
            _fixedInterestRate := mload(0)

            // Get fir interval
            mstore(0x00, _contractTerms)
            _firInterval := mload(0)
        }

        unchecked {
            // Check lender royalties
            if (_lenderRoyalties > 100) {
                revert InvalidLoanParameter(_LENDER_ROYALTIES_ERROR_ID_);
            }

            // Check terms expiry
            if (_termsExpiry < _SECONDS_PER_24_MINUTES_RATIO_SCALED_) {
                revert InvalidLoanParameter(_TIME_EXPIRY_ERROR_ID_);
            }

            // Check duration and grace period
            if (
                uint256(_duration) == 0 ||
                (uint256(_loanStart) +
                    uint256(_duration) +
                    uint256(_gracePeriod)) >
                type(uint32).max
            ) {
                revert InvalidLoanParameter(_DURATION_ERROR_ID_);
            }

            // Check principal
            if (_principal == 0)
                revert InvalidLoanParameter(_PRINCIPAL_ERROR_ID_);

            // No fixed interest rate check necessary

            // Check FIR interval
            if (_firInterval > 15)
                revert InvalidLoanParameter(_FIR_INTERVAL_ERROR_ID_);

            // Check max compounded debt
            try
                LibLoanContractInterest.compoundWithTopoff(
                    _principal,
                    _fixedInterestRate,
                    _getTotalFirIntervals(_firInterval, _duration)
                )
            returns (uint256) {} catch {
                if (_firInterval != 0)
                    revert InvalidLoanParameter(_FIXED_INTEREST_RATE_ERROR_ID_);
            }
        }
    }

    function _getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) internal view returns (uint256) {
        // console.log(_seconds / _MINUTELY_MULTIPLIER_);

        // _SECONDLY_
        if (_firInterval == 0) {
            return _seconds;
        }
        // _MINUTELY_
        else if (_firInterval == 1) {
            return _seconds / _MINUTELY_MULTIPLIER_;
        }
        // _HOURLY_
        else if (_firInterval == 2) {
            return _seconds / _HOURLY_MULTIPLIER_;
        }
        // _DAILY_
        else if (_firInterval == 3) {
            return _seconds / _DAILY_MULTIPLIER_;
        }
        // _WEEKLY_
        else if (_firInterval == 4) {
            return _seconds / _WEEKLY_MULTIPLIER_;
        }
        // _2_WEEKLY_
        else if (_firInterval == 5) {
            return _seconds / _2_WEEKLY_MULTIPLIER_;
        }
        // _4_WEEKLY_
        else if (_firInterval == 6) {
            return _seconds / _4_WEEKLY_MULTIPLIER_;
        }
        // _6_WEEKLY_
        else if (_firInterval == 7) {
            return _seconds / _6_WEEKLY_MULTIPLIER_;
        }
        // _8_WEEKLY_
        else if (_firInterval == 8) {
            return _seconds / _8_WEEKLY_MULTIPLIER_;
        }
        // _360_DAILY_
        else if (_firInterval == 14) {
            return _seconds / _360_DAILY_MULTIPLIER_;
        }

        return 0;
    }

    function _setLoanAgreement(
        uint32 _now,
        uint256 _debtId,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) internal virtual {
        bytes32 _loanAgreement;

        assembly {
            // Get packed fixed interest rate
            mstore(0x01, _contractTerms)
            let _fixedInterestRate := mload(0)

            // Get packed is direct and commital
            // Need to mask other packed terms for gt
            // comparison below.
            mstore(0x02, _contractTerms)
            let _isDirect_Commital := and(mload(0), 0xFF)

            // Get packed grace period
            mstore(0x13, _contractTerms)
            let _gracePeriod := mload(0)

            // Get packed duration
            mstore(0x17, _contractTerms)
            let _duration := mload(0)

            // Get packed lender royalties
            mstore(0x1f, _contractTerms)
            let _lenderTerms := mload(0)

            // Shif left to make space for loan state
            mstore(0x20, shl(4, _contractTerms))

            // Pack loan state (uint4)
            switch _gracePeriod
            case 0 {
                mstore(
                    0x20,
                    xor(
                        and(_LOAN_STATE_MASK_, mload(0x20)),
                        and(_LOAN_STATE_MAP_, _ACTIVE_STATE_)
                    )
                )
            }
            default {
                mstore(
                    0x20,
                    xor(
                        and(_LOAN_STATE_MASK_, mload(0x20)),
                        and(_LOAN_STATE_MAP_, _ACTIVE_GRACE_STATE_)
                    )
                )
            }

            // Pack fir interval (uint4)
            // Already performed and not needed.

            // Pack fixed interest rate (uint8)
            mstore(
                0x20,
                xor(
                    and(_FIR_MASK_, mload(0x20)),
                    and(_FIR_MAP_, shl(_FIR_POS_, _fixedInterestRate))
                )
            )

            // Pack loan start time (uint32)
            mstore(
                0x20,
                xor(
                    and(_LOAN_START_MASK_, mload(0x20)),
                    and(
                        _LOAN_START_MAP_,
                        shl(_LOAN_START_POS_, add(_now, _gracePeriod))
                    )
                )
            )

            // Pack loan duration time (uint32)
            mstore(
                0x20,
                xor(
                    and(_LOAN_DURATION_MASK_, mload(0x20)),
                    and(
                        _LOAN_DURATION_MAP_,
                        shl(_LOAN_DURATION_POS_, _duration)
                    )
                )
            )

            switch gt(_isDirect_Commital, 0x64)
            case true {
                // Pack is direct (uint4) - true
                mstore(
                    0x20,
                    xor(
                        and(_IS_FIXED_MASK_, mload(0x20)),
                        and(_IS_FIXED_MAP_, shl(_IS_FIXED_POS_, 0x01))
                    )
                )

                // Pack commital (uint8)
                mstore(
                    0x20,
                    xor(
                        and(_COMMITAL_MASK_, mload(0x20)),
                        and(
                            _COMMITAL_MAP_,
                            shl(_COMMITAL_POS_, sub(_isDirect_Commital, 0x65))
                        )
                    )
                )
            }
            case false {
                // Pack is direct (uint4) - false
                mstore(
                    0x20,
                    xor(
                        and(_IS_FIXED_MASK_, mload(0x20)),
                        and(_IS_FIXED_MAP_, shl(_IS_FIXED_POS_, 0x00))
                    )
                )

                // Pack commital (uint8)
                mstore(
                    0x20,
                    xor(
                        and(_COMMITAL_MASK_, mload(0x20)),
                        and(
                            _COMMITAL_MAP_,
                            shl(_COMMITAL_POS_, _isDirect_Commital)
                        )
                    )
                )
            }

            // Pack lender royalties (uint8)
            mstore(
                0x20,
                xor(
                    and(_LENDER_ROYALTIES_MASK_, mload(0x20)),
                    and(
                        _LENDER_ROYALTIES_MAP_,
                        shl(_LENDER_ROYALTIES_POS_, _lenderTerms)
                    )
                )
            )

            // Pack loan count (uint8)
            mstore(
                0x20,
                xor(
                    and(_LOAN_COUNT_MASK_, mload(0x20)),
                    and(
                        _LOAN_COUNT_MAP_,
                        shl(_LOAN_COUNT_POS_, _activeLoanIndex)
                    )
                )
            )

            _loanAgreement := and(_CLEANUP_MASK_, mload(0x20))
        }

        __packedDebtTerms[_debtId] = _loanAgreement;
    }

    function _setLoanState(uint256 _debtId, uint8 _newLoanState) internal {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];
        uint8 _oldLoanState;

        assembly {
            _oldLoanState := and(_LOAN_STATE_MAP_, _contractTerms)

            // If the loan states are the same, do nothing
            if eq(_oldLoanState, _newLoanState) {
                revert(0, 0)
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

        __packedDebtTerms[_debtId] = _contractTerms;

        emit LoanStateChanged(_debtId, _newLoanState, _oldLoanState);
    }

    function _updateLoanTimes(uint256 _debtId) internal {
        bytes32 _contractTerms = __packedDebtTerms[_debtId];

        assembly {
            let _loanState := and(_LOAN_STATE_MAP_, _contractTerms)

            // If loan state is beyond active, do nothing
            if gt(_loanState, _ACTIVE_STATE_) {
                revert(0, 0)
            }

            mstore(0x20, _contractTerms)

            // Store loan close time
            let _loanClose := add(
                shr(16, and(_LOAN_START_MAP_, _contractTerms)),
                shr(48, and(_LOAN_DURATION_MAP_, _contractTerms))
            )

            let _now := timestamp()
            if gt(_now, _loanClose) {
                _now := _loanClose
            }

            // Update loan last checked. This could be a transition from
            // loan start to loan last checked if it is the first time this
            // condition is executed.
            mstore(
                0x20,
                xor(
                    and(_LOAN_START_MASK_, mload(0x20)),
                    and(_LOAN_START_MAP_, shl(16, _now))
                )
            )

            // Update loan duration
            mstore(
                0x20,
                xor(
                    and(_LOAN_DURATION_MASK_, mload(0x20)),
                    and(_LOAN_DURATION_MAP_, shl(48, sub(_loanClose, _now)))
                )
            )

            _contractTerms := mload(0x20)
        }

        __packedDebtTerms[_debtId] = _contractTerms;
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface ILoanManager {
    event LoanTermsRevoked(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );

    event LoanTermsReinstated(
        address indexed borrower,
        bytes32 indexed hashedTerms
    );

    function maxRefinances() external returns (uint256);

    function setMaxRefinances(uint256 _maxRefinances) external;

    function updateLoanState(uint256 _debtId) external;

    function verifyLoanActive(uint256 _debtId) external view;

    function checkLoanActive(uint256 _debtId) external view returns (bool);

    function checkLoanDefault(uint256 _debtId) external view returns (bool);

    function checkLoanExpired(uint256 _debtId) external view returns (bool);
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

////import "../IERC721.sol";

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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

interface ICollateralVault {
    error UnallowedDeposit();
    error UnallowedWithdrawal();
    error IllegalDebtId();

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
        bool vault;
    }

    function totalCollateral() external view returns (uint256);

    function getCollateral(
        uint256 _debtId
    ) external view returns (Collateral memory);

    function setCollateral(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _debtId
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

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface ILoanContract {
    error InvalidCollateral();
    error InvalidParticipant();
    error FailedFundsTransfer();
    error ExceededRefinanceLimit();

    struct Debt {
        uint256 debtId;
        uint256 collateralNonce;
        uint256 activeLoanIndex;
    }

    event LoanContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId,
        uint256 activeLoanIndex
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

    function totalDebts() external returns (uint256);

    function debts(
        address _collateralAddress,
        uint256 _collateralId
    ) external returns (uint256, uint256, uint256);

    function debtIdBranch(
        uint256 _childDebtId
    ) external returns (uint256, uint256, uint256);

    function debtBalanceOf(uint256 _debtId) external view returns (uint256);

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function getCollateralDebtId(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function getActiveLoanIndex(
        address _collateralAddress,
        uint256 _collateralId
    ) external view returns (uint256);

    function initLoanContract(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        bytes calldata _borrowerSignature
    ) external payable;

    function initLoanContract(
        bytes32 _contractTerms,
        uint256 _debtId,
        bytes calldata _borrowerSignature
    ) external payable;

    function mintReplica(uint256 _debtId) external;
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

////import "hardhat/console.sol";

abstract contract LoanSigningUtils {
    function _recoverSigner(
        uint256 _principal,
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _collateralNonce,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 _message = __prefixed(
            keccak256(
                abi.encode(
                    _principal,
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    _collateralNonce
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = __splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }

    function __prefixed(bytes32 _hash) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function __splitSignature(
        bytes memory _signature
    ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

abstract contract TypeUtils {
    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function _toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

////import "./interfaces/ILoanManager.sol";
////import "./LoanCodec.sol";
////import "./access/ManagerAccessController.sol";

contract LoanManager is ILoanManager, LoanCodec, ManagerAccessController {
    // Max number of loan refinances (default is unlimited)
    uint256 public maxRefinances = 2008;

    mapping(address => mapping(bytes32 => bool)) private __revokedTerms;

    constructor() ManagerAccessController() {}

    function setMaxRefinances(
        uint256 _maxRefinances
    ) external onlyRole(_ADMIN_) {
        maxRefinances = _maxRefinances <= 255 ? _maxRefinances : 2008;
    }

    /*
     * @dev Updates loan state.
     */
    function updateLoanState(uint256 _debtId) external onlyRole(_TREASURER_) {
        if (!checkLoanActive(_debtId)) {
            console.log("Inactive loan: %s", _debtId);
            revert InactiveLoanState();
        }

        // Loan defaulted
        if (checkLoanExpired(_debtId)) {
            console.log("Defaulted loan: %s", _debtId);
            _updateLoanTimes(_debtId);
            _setLoanState(_debtId, _DEFAULT_STATE_);
        }
        // Loan fully paid off
        else if (_anzaToken.totalSupply(_debtId * 2) <= 0) {
            console.log("Paid loan: %s", _debtId);
            _setLoanState(_debtId, _PAID_STATE_);
        }
        // Loan active and interest compounding
        else if (loanState(_debtId) == _ACTIVE_STATE_) {
            console.log("Active loan: %s", _debtId);
            _updateLoanTimes(_debtId);
        }
        // Loan no longer in grace period
        else if (!_checkGracePeriod(_debtId)) {
            console.log("Grace period expired: %s", _debtId);
            _setLoanState(_debtId, _ACTIVE_STATE_);
            _updateLoanTimes(_debtId);
        }
    }

    function verifyLoanActive(uint256 _debtId) public view {
        if (!checkLoanActive(_debtId)) revert InactiveLoanState();
    }

    function checkTermsRevoked(
        address _borrower,
        bytes32 _hashedTerms
    ) public view returns (bool) {
        return __revokedTerms[_borrower][_hashedTerms];
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

    function checkLoanExpired(uint256 _debtId) public view returns (bool) {
        return
            _anzaToken.totalSupply(_debtId * 2) > 0 &&
            loanClose(_debtId) <= block.timestamp;
    }

    function revokeTerms(bytes32 _hashedTerms) public {
        __revokedTerms[msg.sender][_hashedTerms] = true;

        emit LoanTermsRevoked(msg.sender, _hashedTerms);
    }

    function reinstateTerms(bytes32 _hashedTerms) public {
        __revokedTerms[msg.sender][_hashedTerms] = false;

        emit LoanTermsReinstated(msg.sender, _hashedTerms);
    }

    function _checkGracePeriod(uint256 _debtId) internal view returns (bool) {
        return loanStart(_debtId) > block.timestamp;
    }
}

/**
 *  SourceUnit: /home/jason/Documents/software/Anza/anza-finance/contracts/LoanContract.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.20;

////import "./LoanManager.sol";
////import "./utils/TypeUtils.sol";
////import "./utils/LoanSigningUtils.sol";
////import "./interfaces/ILoanContract.sol";
////import "./interfaces/ICollateralVault.sol";
////import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract LoanContract is
    ILoanContract,
    LoanManager,
    LoanSigningUtils,
    TypeUtils
{
    // Count of total inactive/active debts
    uint256 public totalDebts;

    // Mapping from collateral to debt ID
    mapping(address _collateralAddress => mapping(uint256 _collateralId => Debt))
        public debts;
    mapping(uint256 _childDebtId => Debt _parentDebtId) public debtIdBranch;

    constructor() LoanManager() {}

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(AccessControl) returns (bool) {
        return
            _interfaceId == 0xb7c3c5ea || // ILoanContract
            _interfaceId == 0x4a23979d || // ILoanManager
            _interfaceId == 0xf83e032d || // ILoanCodec
            AccessControl.supportsInterface(_interfaceId);
    }

    /*
     * This should report back only the total debt tokens, not the ALC NFTs.
     * TODO: Test
     */
    function debtBalanceOf(uint256 _debtId) public view returns (uint256) {
        return _anzaToken.totalSupply(_debtId * 2);
    }

    function getCollateralNonce(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debts[_collateralAddress][_collateralId].collateralNonce + 1;
    }

    function getCollateralDebtId(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debts[_collateralAddress][_collateralId].debtId;
    }

    function getActiveLoanIndex(
        address _collateralAddress,
        uint256 _collateralId
    ) public view returns (uint256) {
        return debts[_collateralAddress][_collateralId].activeLoanIndex;
    }

    /*
     * Input _contractTerms:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   `isFixed` and `commital`
     *  > 008 - [20..27]   `loanCurrency`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     */
    function initLoanContract(
        bytes32 _contractTerms,
        address _collateralAddress,
        uint256 _collateralId,
        bytes calldata _borrowerSignature
    ) external payable {
        // Validate loan terms
        uint32 _now = _toUint32(block.timestamp);
        uint256 _principal = msg.value;
        _validateLoanTerms(_contractTerms, _now, _principal);

        // Verify borrower participation
        IERC721Metadata _collateralToken = IERC721Metadata(_collateralAddress);
        address _borrower = _collateralToken.ownerOf(_collateralId);

        Debt storage _debt = debts[_collateralAddress][_collateralId];

        // Increment loan field
        _debt.debtId = ++totalDebts;
        ++_debt.activeLoanIndex;

        if (
            (_borrower !=
                _recoverSigner(
                    _principal,
                    _contractTerms,
                    _collateralAddress,
                    _collateralId,
                    ++_debt.collateralNonce,
                    _borrowerSignature
                ) ||
                (_borrower == msg.sender))
        ) revert InvalidParticipant();

        // Add debt to database
        __setLoanAgreement(_now, 0, _contractTerms);

        // The collateral ID and address will be mapped within
        // the loan collateral vault to the debt ID.
        _collateralToken.safeTransferFrom(
            _borrower,
            _collateralVault,
            _collateralId,
            abi.encodePacked(totalDebts)
        );

        // Transfer funds to borrower's account in treasurey
        (bool _success, ) = _loanTreasurer.call{value: _principal}(
            abi.encodeWithSignature("depositFunds(address)", _borrower)
        );
        if (!_success) revert FailedFundsTransfer();

        // Mint debt ALC debt tokens for lender
        _anzaToken.mint(
            msg.sender,
            totalDebts * 2,
            _principal,
            _collateralToken.tokenURI(_collateralId),
            abi.encodePacked(_borrower, totalDebts)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateralAddress,
            _collateralId,
            totalDebts,
            0
        );
    }

    /*
     * Input _contractTerms:
     *  > 004 - [0..3]     `firInterval`
     *  > 004 - [4..11]    `fixedInterestRate`
     *  > 008 - [12..19]   unused space
     *  > 128 - [20..147]  `principal`
     *  > 032 - [148..179] `gracePeriod`
     *  > 032 - [180..211] `duration`
     *  > 032 - [212..243] `termsExpiry`
     *  > 008 - [244..255] `lenderRoyalties`
     */
    function initLoanContract(
        bytes32 _contractTerms,
        uint256 _debtId,
        bytes calldata _borrowerSignature
    ) external payable {
        // Verify existing loan is in good standing
        if (checkLoanDefault(_debtId)) revert InvalidCollateral();

        // Validate loan terms
        uint32 _now = _toUint32(block.timestamp);
        uint256 _principal = msg.value;
        _validateLoanTerms(_contractTerms, _now, _principal);

        ICollateralVault _loanCollateralVault = ICollateralVault(
            _collateralVault
        );
        ICollateralVault.Collateral memory _collateral = _loanCollateralVault
            .getCollateral(_debtId);

        Debt storage _debt = debts[_collateral.collateralAddress][
            _collateral.collateralId
        ];

        // Map the child loan to the parent
        debtIdBranch[_debt.debtId] = _debt;

        // Increment child loan fields
        _debt.debtId = ++totalDebts;
        ++_debt.activeLoanIndex;

        // Verify borrower participation
        address _borrower = _recoverSigner(
            _principal,
            _contractTerms,
            _collateral.collateralAddress,
            _collateral.collateralId,
            ++_debt.collateralNonce,
            _borrowerSignature
        );

        // During initial loan submission (i.e. activeLoanIndex 0), in the
        // AnzaToken contract, the borrower is given admin role specific to
        // the debt ID. This is then used for borrower verification.
        if (
            !_anzaToken.checkBorrowerOf(_borrower, _debtId) ||
            (_borrower == msg.sender)
        ) revert InvalidParticipant();

        __setLoanAgreement(_now, _debt.activeLoanIndex, _contractTerms);

        // Store collateral-debtId mapping in vault
        _loanCollateralVault.setCollateral(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts
        );

        // Replace or reduce previous debt. Any excess funds will
        // be available for withdrawal in the treasurey.
        uint256 _balance = debtBalanceOf(_debtId);
        (bool _success, ) = _loanTreasurer.call{
            value: _principal >= _balance ? _balance : _principal
        }(
            abi.encodeWithSignature(
                "sponsorPayment(address,uint256)",
                _borrower,
                _debtId
            )
        );
        if (!_success) revert FailedFundsTransfer();

        // Mint debt ALC debt tokens for lender.
        _anzaToken.mint(
            msg.sender,
            totalDebts * 2,
            _principal,
            IERC721Metadata(_collateral.collateralAddress).tokenURI(
                _collateral.collateralId
            ),
            abi.encodePacked(_borrower, totalDebts)
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateral.collateralAddress,
            _collateral.collateralId,
            totalDebts,
            _debt.activeLoanIndex
        );
    }

    function mintReplica(uint256 _debtId) external {
        // AnzaToken.sol manages replica mint access control.
        address _borrower = msg.sender;

        _anzaToken.mint(
            _borrower,
            (_debtId * 2) + 1,
            1,
            "",
            abi.encodePacked(_borrower, _debtId)
        );
    }

    function __setLoanAgreement(
        uint32 _now,
        uint256 _activeLoanIndex,
        bytes32 _contractTerms
    ) private {
        if (_activeLoanIndex > maxRefinances) revert ExceededRefinanceLimit();

        _setLoanAgreement(_now, totalDebts, _activeLoanIndex, _contractTerms);
    }
}
