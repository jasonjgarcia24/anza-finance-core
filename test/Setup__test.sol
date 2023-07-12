// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import "@lending-constants/LoanContractRoles.sol";
import "@markets-constants/AnzaDebtMarketRoles.sol";

import {LoanContract} from "@base/LoanContract.sol";
import {CollateralVault} from "@services/CollateralVault.sol";
import {LoanTreasurey} from "@services/LoanTreasurey.sol";
import {ICollateralVault} from "@services-interfaces/ICollateralVault.sol";
import {ILoanNotary, IDebtNotary, ISponsorshipNotary, IRefinanceNotary} from "@services-interfaces/ILoanNotary.sol";
import {AnzaToken} from "@tokens/AnzaToken.sol";
import {AnzaDebtMarket} from "@markets/AnzaDebtMarket.sol";
import {AnzaDebtStorefront} from "@storefronts/AnzaDebtStorefront.sol";
import {AnzaSponsorshipStorefront} from "@storefronts/AnzaSponsorshipStorefront.sol";
import {AnzaRefinanceStorefront} from "@storefronts/AnzaRefinanceStorefront.sol";
import {AnzaNotary as Notary} from "@lending-libraries/AnzaNotary.sol";

import "@test-databases/TestConstants__test.sol";
import {DemoToken} from "@test-utils/DemoToken.sol";
import {IERC1155Events} from "@test-utils/events/ERC1155EventsSuite__test.sol";
import {IAccessControlEvents} from "@test-utils-interfaces/IAccessControlEvents__test.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Utils is Test {
    /* ------------------------------------------------ *
     *                    CONSTANTS                     *
     * ------------------------------------------------ */
    string public constant _BASE_URI_ = "https://www.a_base_uri.com/";
    string public baseURI = "https://www.demo_token_metadata_uri.com/";
    uint256 public constant collateralId = 5;

    function getTokenURI(uint256 _tokenId) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _BASE_URI_,
                    "debt-token/",
                    Strings.toString(_tokenId)
                )
            );
    }

    function getAccessControlFailMsg(
        bytes32 _role,
        address _account
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(_account), 20),
                    " is missing role ",
                    Strings.toHexString(uint256(_role), 32)
                )
            );
    }

    function unexpectedFail(string memory _reason, bytes memory _err) public {
        emit log(string(abi.encodePacked("Error: ", _reason)));
        emit log_named_bytes("Unexpected error", _err);
        assertTrue(false);
    }

    function unexpectedFail(string memory _reason, string memory _err) public {
        emit log(string(abi.encodePacked("Error: ", _reason)));
        emit log_named_string("Unexpected error", _err);
        assertTrue(false);
    }
}

abstract contract Settings is Utils {
    /* ------------------------------------------------ *
     *                     ACCOUNTS                     *
     * ------------------------------------------------ */
    address public borrower = vm.envAddress("DEAD_ACCOUNT_KEY_0");
    address public treasurer = vm.envAddress("DEAD_ACCOUNT_KEY_2");
    address public collector = vm.envAddress("DEAD_ACCOUNT_KEY_3");
    address public admin = vm.envAddress("DEAD_ACCOUNT_KEY_4");
    address public lender = vm.envAddress("DEAD_ACCOUNT_KEY_5");
    address public alt_account = vm.envAddress("DEAD_ACCOUNT_KEY_9");

    uint256 public borrowerPrivKey = vm.envUint("DEAD_ACCOUNT_PRIVATE_KEY_0");
    uint256 public lenderPrivKey = vm.envUint("DEAD_ACCOUNT_PRIVATE_KEY_5");
    uint256 public altAccountPrivKey = vm.envUint("DEAD_ACCOUNT_PRIVATE_KEY_9");

    uint256 public collateralNonce;
    bytes32 public contractTerms;
    bytes public signature;

    /* ------------------------------------------------ *
     *                   CONTRACTS                      *
     * ------------------------------------------------ */
    CollateralVault public collateralVault;
    LoanContract public loanContract;
    LoanTreasurey public loanTreasurer;
    AnzaToken public anzaToken;
    DemoToken public demoToken;
    DemoToken public alt_demoToken;

    AnzaDebtMarket public anzaDebtMarket;
    AnzaDebtStorefront public anzaDebtStorefront;
    AnzaSponsorshipStorefront public anzaSponsorshipStorefront;
    AnzaRefinanceStorefront public anzaRefinanceStorefront;

    /* ------------------------------------------------ *
     *                   DOMAIN SEPS                    *
     * ------------------------------------------------ */
    Notary.DomainSeparator public loanDomainSeparator;
    Notary.DomainSeparator public debtDomainSeparator;
    Notary.DomainSeparator public sponsorshipDomainSeparator;
    Notary.DomainSeparator public refinanceDomainSeparator;

    /* ------------------------------------------------ *
     *           CONTRACT TERMS CONSTRUCTION            *
     * ------------------------------------------------ */
    struct ContractTerms {
        uint8 firInterval;
        uint8 fixedInterestRate;
        uint8 isFixed;
        uint8 commitalRatio;
        uint256 commitalPeriod;
        uint256 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
        uint8 lenderRoyalties;
    }

    function setCommitalDuration(
        ContractTerms memory _contractTerms
    ) public view returns (ContractTerms memory) {
        uint256 _start = block.timestamp + _contractTerms.gracePeriod;
        uint256 _commitalDuration = (uint256(_contractTerms.duration) *
            _contractTerms.commitalRatio) / 0x64;

        _contractTerms.commitalPeriod = _commitalDuration > 0
            ? _start + _commitalDuration
            : _start;

        return _contractTerms;
    }

    function setDurationLessGracePeriod(
        ContractTerms memory _contractTerms
    ) public pure returns (ContractTerms memory) {
        _contractTerms.duration = _contractTerms.gracePeriod <=
            _contractTerms.duration
            ? _contractTerms.duration - _contractTerms.gracePeriod
            : _contractTerms.duration;

        return _contractTerms;
    }

    function createPackedContractTerms()
        public
        virtual
        returns (bytes32, ContractTerms memory)
    {
        return
            createPackedContractTerms(
                ContractTerms({
                    firInterval: _FIR_INTERVAL_,
                    fixedInterestRate: _FIXED_INTEREST_RATE_,
                    isFixed: _IS_FIXED_,
                    commitalRatio: _COMMITAL_RATIO_,
                    commitalPeriod: 0x00,
                    principal: _PRINCIPAL_,
                    gracePeriod: _GRACE_PERIOD_,
                    duration: _DURATION_,
                    termsExpiry: _TERMS_EXPIRY_,
                    lenderRoyalties: _LENDER_ROYALTIES_
                })
            );
    }

    function createPackedContractTerms(
        ContractTerms memory _contractTerms
    ) public view virtual returns (bytes32, ContractTerms memory) {
        uint8 _firInterval = _contractTerms.firInterval;
        uint8 _fixedInterestRate = _contractTerms.fixedInterestRate;
        uint8 _isDirect = _contractTerms.isFixed;
        uint8 _commitalRatio = _contractTerms.commitalRatio;
        uint32 _gracePeriod = _contractTerms.gracePeriod;
        uint32 _duration = _contractTerms.duration;
        uint32 _termsExpiry = _contractTerms.termsExpiry;
        uint8 _lenderRoyalties = _contractTerms.lenderRoyalties;

        bytes32 _packedContractTerms;

        assembly {
            mstore(0x20, _firInterval)
            mstore(0x1f, _fixedInterestRate)

            if eq(_isDirect, 0x01) {
                _commitalRatio := add(0x65, _commitalRatio)
            }
            mstore(0x1e, _commitalRatio)

            mstore(0x0d, _gracePeriod)
            mstore(0x09, _duration)
            mstore(0x05, _termsExpiry)
            mstore(0x01, _lenderRoyalties)

            _packedContractTerms := mload(0x20)
        }

        _contractTerms = setDurationLessGracePeriod(_contractTerms);
        _contractTerms = setCommitalDuration(_contractTerms);

        return (_packedContractTerms, _contractTerms);
    }
}

contract LoanContractHarness is LoanContract {
    constructor() LoanContract() {}

    function exposed__getTotalFirIntervals(
        uint256 _firInterval,
        uint256 _seconds
    ) public pure returns (uint256) {
        return _getTotalFirIntervals(_firInterval, _seconds);
    }
}

abstract contract Setup is Settings, IERC1155Events, IAccessControlEvents {
    function setUp() public virtual {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);

        // Deploy AnzaToken
        anzaToken = new AnzaToken("www.anza.io");

        // Deploy LoanContract
        loanContract = new LoanContract();

        // Deploy LoanTreasurey
        loanTreasurer = new LoanTreasurey();

        // Deploy CollateralVault
        collateralVault = new CollateralVault(address(anzaToken));

        // Set AnzaToken access control roles
        anzaToken.grantRole(_LOAN_CONTRACT_, address(loanContract));
        anzaToken.grantRole(_TREASURER_, address(loanTreasurer));
        anzaToken.grantRole(_COLLATERAL_VAULT_, address(collateralVault));

        // Set LoanContract access control roles
        loanContract.setAnzaToken(address(anzaToken));
        loanContract.grantRole(_TREASURER_, address(loanTreasurer));
        loanContract.setCollateralVault(address(collateralVault));

        // Set LoanTreasurey access control roles
        loanTreasurer.setAnzaToken(address(anzaToken));
        loanTreasurer.grantRole(_LOAN_CONTRACT_, address(loanContract));
        loanTreasurer.grantRole(_COLLATERAL_VAULT_, address(collateralVault));

        // Set CollateralVault access control roles
        collateralVault.setLoanContract(address(loanContract));
        collateralVault.grantRole(_TREASURER_, address(loanTreasurer));

        vm.stopPrank();

        vm.startPrank(borrower);
        demoToken = new DemoToken(10);
        demoToken.approve(address(loanContract), collateralId);
        demoToken.setApprovalForAll(address(loanContract), true);

        alt_demoToken = new DemoToken(10);
        alt_demoToken.approve(address(loanContract), collateralId);
        alt_demoToken.setApprovalForAll(address(loanContract), true);
        vm.stopPrank();

        // Set Anza Debt Marketplace and Storefronts
        vm.startPrank(admin);
        anzaDebtMarket = new AnzaDebtMarket();

        anzaDebtStorefront = new AnzaDebtStorefront(
            address(anzaToken),
            address(loanContract),
            address(loanTreasurer)
        );

        anzaSponsorshipStorefront = new AnzaSponsorshipStorefront(
            address(anzaToken),
            address(loanContract),
            address(loanTreasurer)
        );

        anzaRefinanceStorefront = new AnzaRefinanceStorefront(
            address(anzaToken),
            address(loanContract),
            address(loanTreasurer)
        );

        // Set Anza Debt Marketplace access control roles
        anzaDebtMarket.grantRole(
            _DEBT_STOREFRONT_,
            address(anzaDebtStorefront)
        );

        anzaDebtMarket.grantRole(
            _SPONSORSHIP_STOREFRONT_,
            address(anzaSponsorshipStorefront)
        );

        anzaDebtMarket.grantRole(
            _REFINANCE_STOREFRONT_,
            address(anzaRefinanceStorefront)
        );

        // Set access control roles for debt storefront
        loanTreasurer.grantRole(_DEBT_MARKET_, address(anzaDebtMarket));
        vm.stopPrank();

        loanDomainSeparator = Notary.DomainSeparator({
            name: "LoanNotary",
            version: "0",
            chainId: block.chainid,
            contractAddress: address(loanContract)
        });

        debtDomainSeparator = Notary.DomainSeparator({
            name: "AnzaDebtStorefront",
            version: "0",
            chainId: block.chainid,
            contractAddress: address(anzaDebtStorefront)
        });

        sponsorshipDomainSeparator = Notary.DomainSeparator({
            name: "AnzaSponsorshipStorefront",
            version: "0",
            chainId: block.chainid,
            contractAddress: address(anzaSponsorshipStorefront)
        });

        refinanceDomainSeparator = Notary.DomainSeparator({
            name: "AnzaRefinanceStorefront",
            version: "0",
            chainId: block.chainid,
            contractAddress: address(anzaRefinanceStorefront)
        });
    }

    function createListingSignature(
        uint256 _sellerPrivateKey,
        IDebtNotary.DebtParams memory _debtParams
    ) public virtual returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            _debtParams,
            debtDomainSeparator
        );

        // Sign seller's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_sellerPrivateKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function createListingSignature(
        uint256 _sellerPrivateKey,
        ISponsorshipNotary.SponsorshipParams memory _sponsorshipParams
    ) public virtual returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            address(anzaToken),
            _sponsorshipParams,
            sponsorshipDomainSeparator
        );

        // Sign seller's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_sellerPrivateKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function createListingSignature(
        uint256 _sellerPrivateKey,
        IRefinanceNotary.RefinanceParams memory _refinanceParams
    ) public virtual returns (bytes memory _signature) {
        bytes32 _message = Notary.typeDataHash(
            address(anzaToken),
            _refinanceParams,
            refinanceDomainSeparator
        );

        // Sign seller's listing terms
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_sellerPrivateKey, _message);
        _signature = abi.encodePacked(r, s, v);
    }

    function mintDemoTokens(uint256 _amount) public virtual {
        vm.startPrank(borrower);
        demoToken.mint(_amount);
        vm.stopPrank();
    }
}
