// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {LibOfficerRoles as Roles, LibTokenTypes as TokenTypes, LibLoanContractMetadata as Metadata, LibLoanContractInit as Init, LibLoanContractIndexer as Indexer} from "./libraries/LibLoanContract.sol";
import {LibLoanContractStates as States} from "./utils/LibLoanContractStates.sol";
import "./utils/StateControl.sol";
import "./interfaces/ILoanContract.sol";
import "hardhat/console.sol";

contract LoanContract is AccessControl, ERC1155URIStorage, ERC1155Holder {
    using StateControlUint256 for StateControlUint256.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;

    event LoanContractInitialized(
        address indexed collateralAddress,
        uint256 indexed collateralId,
        uint256 indexed debtId
    );

    string private constant _name = "Anza Loan Contract";
    string private constant _symbol = "ALC";
    address public immutable arbiter;

    uint256 private _totalDebtSupply;

    States.LoanState[] public loanStates;
    Metadata.TokenData[] public tokens;

    mapping(address => mapping(uint256 => uint256[])) public debtIds;
    mapping(uint256 => address) public borrowers;
    mapping(uint256 => address) public lenders;
    mapping(uint256 => address) public debtOwners;
    mapping(uint256 => uint256) private _totalSupply;

    constructor(
        address _admin,
        address _arbiter,
        address _treasurer,
        address _collector,
        string memory _baseCollectionURI
    ) ERC1155(_baseCollectionURI) {
        _setRoleAdmin(Roles._ADMIN_, Roles._ADMIN_);
        _setRoleAdmin(Roles._FACTORY_, Roles._FACTORY_);
        _setRoleAdmin(Roles._TREASURER_, Roles._ADMIN_);
        _setRoleAdmin(Roles._COLLECTOR_, Roles._ADMIN_);

        _grantRole(Roles._ADMIN_, _admin);
        _grantRole(Roles._FACTORY_, msg.sender);
        _grantRole(Roles._TREASURER_, _treasurer);
        _grantRole(Roles._COLLECTOR_, _collector);

        arbiter = _arbiter;
    }

    /*
     * This should report back only the total debt tokens, not the ALC NFTs.
     * TODO: Test
     */
    function totalDebtSupply(uint256 _debtId) public view returns (uint256) {
        return _totalSupply[_debtId];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function debtExists(uint256 _debtId) public view returns (bool) {
        return totalDebtSupply(_debtId) > 0;
    }

    // TODO: Test
    function submitProposal(
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration,
        uint256 _stopBlockstamp
    ) external payable {
        // Only allow loan contract proposals for NFTs that are not currently
        // collateralized in an active loan
        uint256[] storage _collateralDebtIds = debtIds[_collateralAddress][
            _collateralId
        ];
        uint256 _numDebtIds = _collateralDebtIds.length;

        require(
            _numDebtIds == 0 ||
                States.isInactiveState(
                    loanStates[_collateralDebtIds[_numDebtIds - 1]]
                ),
            "State must not be between FUNDED and COLLECTION exclusively"
        );

        // Create new debt token metadata
        tokens.push();
        Metadata.TokenData storage _token = tokens[_totalDebtSupply];

        address[2] memory _participants = Init.initializeALCTokens(
            _token,
            arbiter,
            _collateralAddress,
            _collateralId,
            _principal,
            _fixedInterestRate,
            _duration,
            _stopBlockstamp
        );

        // Add debt ID to collateral mapping
        _collateralDebtIds.push(_totalDebtSupply);

        // Mint NFTs for borrower and lender
        __mintParticipantTokens(_participants);

        // Update loan contract state
        loanStates.push(
            _token.borrowerSigned.get()
                ? States.LoanState.UNSPONSORED
                : States.LoanState.NONLEVERAGED
        );

        // Emit initialization event
        emit LoanContractInitialized(
            _collateralAddress,
            _collateralId,
            _totalDebtSupply
        );

        // Setup for next debt ID
        _totalDebtSupply += 1;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(AccessControl, ERC1155Receiver, ERC1155)
        returns (bool)
    {
        return
            _interfaceId == type(ILoanContract).interfaceId ||
            ERC1155.supportsInterface(_interfaceId) ||
            ERC1155Receiver.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }

    // TODO: Test
    function depositCollateral(uint256 _debtId) external {
        Init.depositCollateral(
            arbiter,
            tokens[_debtId].collateralAddress.get(),
            tokens[_debtId].collateralId.get()
        );
    }

    // NOTE: Tested
    function withdrawCollateral(uint256 _debtId) external {
        // States.LoanState _loanState = loanStates[_debtId];
        // address _borrower = Indexer.borrower(_debtId);
        // Metadata.TokenData storage _token = tokens[_debtId];
        // IERC721(_token.collateralAddress.get()).safeTransferFrom(
        //     address(this),
        //     _borrower,
        //     _token.collateralId.get(),
        //     ""
        // );
        // if (_loanState != States.LoanState.PAID) {
        //     loanStates[_debtId] = States.LoanState.NONLEVERAGED;
        // }
    }

    function depositFunding(uint256 _debtId) external payable {
        require(
            msg.value == tokens[_debtId].principal.get(),
            "msg.value must match loan principal"
        );

        require(
            loanStates[_debtId] < States.LoanState.FUNDED,
            "The loan is already funded"
        );

        loanStates[_debtId] = States.LoanState.FUNDED;
    }

    function withdrawFunding() external {}

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function __mintParticipantTokens(address[2] memory _participants) private {
        // Borrower token
        _mint(
            _participants[0],
            _totalDebtSupply,
            1,
            abi.encodePacked(TokenTypes._BORROWER_TOKEN_)
        );

        // Lender token
        _mint(
            _participants[1],
            _totalDebtSupply,
            1,
            abi.encodePacked(TokenTypes._LENDER_TOKEN_)
        );
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        // Update participant mapping per mint type
        if (
            keccak256(data) ==
            keccak256(abi.encodePacked(TokenTypes._BORROWER_TOKEN_))
        ) {
            borrowers[ids[0] + 1] = to;
        } else if (
            keccak256(data) ==
            keccak256(abi.encodePacked(TokenTypes._LENDER_TOKEN_))
        ) {
            lenders[ids[0] + 2] = to;
        } else {
            debtOwners[ids[0]] = to;
        }

        // Update total supply
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(
                    supply >= amount,
                    "ERC1155: burn amount exceeds totalSupply"
                );
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}
