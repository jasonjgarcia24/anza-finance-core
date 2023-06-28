// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import "@lending-constants/LoanNotaryTypeHashes.sol";
import {StdNotaryErrors} from "@custom-errors/StdNotaryErrors.sol";

import {ILoanNotary, IDebtNotary, ISponsorshipNotary, IRefinanceNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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

        (uint8 v, bytes32 r, bytes32 s) = Notary.splitSignature(_signature);

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

        (uint8 v, bytes32 r, bytes32 s) = Notary.splitSignature(_signature);

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

        (uint8 v, bytes32 r, bytes32 s) = Notary.splitSignature(_signature);

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

        (uint8 v, bytes32 r, bytes32 s) = Notary.splitSignature(_signature);

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
