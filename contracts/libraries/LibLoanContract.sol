// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/ILoanContract.sol";
import {LibLoanContractStates as States} from "../utils/LibLoanContractStates.sol";
import "../utils/StateControl.sol";
import "../utils/BlockTime.sol";
import "hardhat/console.sol";

library LibOfficerRoles {
    bytes32 public constant _ADMIN_ = "ADMIN";
    bytes32 public constant _FACTORY_ = "FACTORY";
    bytes32 public constant _LOAN_CONTRACT_ = "LOAN_CONTRACT";
    bytes32 public constant _OWNER_ = "OWNER";
    bytes32 public constant _TREASURER_ = "TREASURER";
    bytes32 public constant _COLLECTOR_ = "COLLECTOR";
}

library LibTokenTypes {
    bytes32 public constant _BORROWER_TOKEN_ = "BORROWER_TOKEN";
    bytes32 public constant _LENDER_TOKEN_ = "LENDER_TOKEN";
}

library LibLoanContractMetadata {
    struct TokenData {
        StateControlAddress.Property collateralAddress;
        StateControlUint256.Property collateralId;
        StateControlUint256.Property principal;
        StateControlUint256.Property fixedInterestRate;
        StateControlUint256.Property duration;
        StateControlUint256.Property unpaidBalance;
        StateControlUint256.Property paidBalance;
        StateControlUint256.Property stopBlockstamp;
        StateControlBool.Property borrowerSigned;
        StateControlBool.Property lenderSigned;
    }
}

library LibLoanContractInit {
    using StateControlUint256 for StateControlUint256.Property;
    using StateControlAddress for StateControlAddress.Property;
    using StateControlBool for StateControlBool.Property;
    using BlockTime for uint256;

    function initializeALCTokens(
        LibLoanContractMetadata.TokenData storage _tk,
        address _arbiter,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _principal,
        uint256 _fixedInterestRate,
        uint256 _duration,
        uint256 _stopBlockstamp
    ) public returns (address[2] memory) {
        IERC721 _collateralToken = IERC721(_collateralAddress);

        address _owner = _collateralToken.ownerOf(_collateralId);
        address _caller = msg.sender;
        bool _callerIsOwner = _owner == _caller;

        _tk.collateralAddress.init(
            _collateralAddress,
            States.LoanState.UNDEFINED
        );
        _tk.collateralId.init(_collateralId, States.LoanState.UNDEFINED);
        _tk.principal.init(_principal, States.LoanState.FUNDED);
        _tk.fixedInterestRate.init(_fixedInterestRate, States.LoanState.FUNDED);
        _tk.duration.init(_duration, States.LoanState.FUNDED);
        _tk.stopBlockstamp.init(_stopBlockstamp, States.LoanState.FUNDED);

        _tk.borrowerSigned.init(_callerIsOwner, States.LoanState.FUNDED);
        _tk.lenderSigned.init(!_callerIsOwner, States.LoanState.FUNDED);

        if (_callerIsOwner) {
            _collateralToken.safeTransferFrom(
                _owner,
                _arbiter,
                _collateralId,
                abi.encodePacked(_collateralAddress)
            );
            require(msg.value == 0, "Borrower cannot deposit ETH");
        } else {
            require(
                msg.value == _principal,
                "msg.value must match loan principal"
            );
        }

        return [
            _callerIsOwner ? _owner : address(this), // borrower
            !_callerIsOwner ? _caller : address(this) // lender
        ];
    }

    function depositCollateral(
        address _to,
        address _collateralAddress,
        uint256 _collateralId
    ) public {
        IERC721 _collateralToken = IERC721(_collateralAddress);
        address _owner = _collateralToken.ownerOf(_collateralId);

        _collateralToken.safeTransferFrom(_owner, _to, _collateralId, "");
    }
}

library LibLoanContractIndexer {
    // // TODO: Test
    // function borrower(uint256 _debtId) public view returns (address) {
    //     address _borrower = IERC1155(address(this)).balanceOf(
    //         borrowerToken(_debtId)
    //     );
    //     if (_borrower == address(this)) {
    //         return address(0);
    //     }
    //     return _borrower;
    // }
    // // TODO: Test
    // function borrower(address _alcTokenAddress, uint256 _debtId)
    //     public
    //     view
    //     returns (address)
    // {
    //     address _borrower = IERC1155(_alcTokenAddress).ownerOf(
    //         borrowerToken(_alcTokenAddress, _debtId)
    //     );
    //     if (_borrower == _alcTokenAddress) {
    //         return address(0);
    //     }
    //     return _borrower;
    // }
    // // TODO: Test
    // function lender(uint256 _debtId) public view returns (address) {
    //     address _lender = IERC1155(address(this)).ownerOf(lenderToken(_debtId));
    //     if (_lender == address(this)) {
    //         return address(0);
    //     }
    //     return _lender;
    // }
    // // TODO: Test
    // function lender(address _alcTokenAddress, uint256 _debtId)
    //     public
    //     view
    //     returns (address)
    // {
    //     address _lender = IERC1155(_alcTokenAddress).ownerOf(
    //         lenderToken(_alcTokenAddress, _debtId)
    //     );
    //     if (_lender == _alcTokenAddress) {
    //         return address(0);
    //     }
    //     return _lender;
    // }
    // // TODO: Test
    // function borrowerToken(uint256 _debtId) public view returns (uint256) {
    //     return IERC1155(address(this)).tokenByIndex(_debtId * 2);
    // }
    // function borrowerToken(address _alcTokenAddress, uint256 _debtId)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return IERC1155(_alcTokenAddress).tokenByIndex(_debtId * 2);
    // }
    // // TODO: Test
    // function lenderToken(uint256 _debtId) public view returns (uint256) {
    //     return IERC1155(address(this)).tokenByIndex((_debtId * 2) + 1);
    // }
    // // TODO: Test
    // function lenderToken(address _alcTokenAddress, uint256 _debtId)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return IERC1155(_alcTokenAddress).tokenByIndex((_debtId * 2) + 1);
    // }
    // // TODO: Test
    // function currentDebtId(address _alcTokenAddress)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return ILoanContract(_alcTokenAddress).totalDebtSupply();
    // }
}
