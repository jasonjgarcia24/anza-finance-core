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

    /* ------------------------------------------------ *
     *                  LOAN TERMS                      *
     * ------------------------------------------------ */
    uint8 public constant _FIR_INTERVAL_ = 14;
    uint8 public constant _FIXED_INTEREST_RATE_ = 10; // 0.10
    uint8 public constant _IS_FIXED_ = 0; // false
    uint8 public constant _COMMITAL_ = 25; // 0.25
    uint256 public constant _PRINCIPAL_ = 10000000000; // WEI
    uint32 public constant _GRACE_PERIOD_ = 86400;
    uint32 public constant _DURATION_ = 1209600;
    uint32 public constant _TERMS_EXPIRY_ = 86400;
    uint8 public constant _LENDER_ROYALTIES_ = 10;

    uint8 public constant _ALT_FIR_INTERVAL_ = 14;
    uint8 public constant _ALT_FIXED_INTEREST_RATE_ = 5; // 0.05
    uint256 public constant _ALT_PRINCIPAL_ = 4; // ETH // 226854911280625642308916404954512140970
    uint32 public constant _ALT_GRACE_PERIOD_ = 60 * 60 * 24 * 5; // 604800 (5 days)
    uint32 public constant _ALT_DURATION_ = 60 * 60 * 24 * 360 * 1; // 62208000 (1 year)
    uint32 public constant _ALT_TERMS_EXPIRY_ = 60 * 60 * 24 * 4; // 1209600 (4 days)
    uint8 public constant _ALT_LENDER_ROYALTIES_ = 10; // 0.10

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
        uint8 commital;
        uint256 principal;
        uint32 gracePeriod;
        uint32 duration;
        uint32 termsExpiry;
        uint8 lenderRoyalties;
    }

    function createContractTerms()
        public
        virtual
        returns (bytes32 _contractTerms)
    {
        assembly {
            mstore(0x20, _FIR_INTERVAL_)
            mstore(0x1f, _FIXED_INTEREST_RATE_)
            mstore(0x0d, _GRACE_PERIOD_)
            mstore(0x09, _DURATION_)
            mstore(0x05, _TERMS_EXPIRY_)
            mstore(0x01, _LENDER_ROYALTIES_)

            _contractTerms := mload(0x20)
        }
    }

    function createContractTerms(
        ContractTerms memory _terms
    ) public view virtual returns (bytes32 _contractTerms) {
        uint8 _firInterval = _terms.firInterval;
        uint8 _fixedInterestRate = _terms.fixedInterestRate;
        uint8 _isDirect = _terms.isFixed;
        uint8 _commital = _terms.commital;
        uint32 _gracePeriod = _terms.gracePeriod;
        uint32 _duration = _terms.duration;
        uint32 _termsExpiry = _terms.termsExpiry;
        uint8 _lenderRoyalties = _terms.lenderRoyalties;

        assembly {
            mstore(0x20, _firInterval)
            mstore(0x1f, _fixedInterestRate)

            if eq(_isDirect, 0x01) {
                _commital := add(0x65, _commital)
            }
            mstore(0x1e, _commital)

            mstore(0x0d, _gracePeriod)
            mstore(0x09, _duration)
            mstore(0x05, _termsExpiry)
            mstore(0x01, _lenderRoyalties)

            _contractTerms := mload(0x20)
        }
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

    // function createContractSignature(
    //     uint256 _principal,
    //     uint256 _collateralId,
    //     uint256 _collateralNonce,
    //     bytes32 _contractTerms
    // ) public virtual returns (bytes memory _signature) {
    //     // Create message for signing
    //     bytes32 _message = Notary.typeDataHash(
    //         ILoanNotary.ContractParams({
    //             principal: _principal,
    //             contractTerms: _contractTerms,
    //             collateralAddress: address(demoToken),
    //             collateralId: _collateralId,
    //             collateralNonce: _collateralNonce
    //         }),
    //         Notary.DomainSeparator({
    //             name: "LoanContract",
    //             version: "0",
    //             chainId: block.chainid,
    //             contractAddress: address(loanContract)
    //         })
    //     );

    //     // Sign borrower's terms
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPrivKey, _message);
    //     _signature = abi.encodePacked(r, s, v);
    // }

    // function createContractSignature(
    //     uint256 _signerPrivKey,
    //     uint256 _principal,
    //     address _collateralAddress,
    //     uint256 _collateralId,
    //     uint256 _collateralNonce,
    //     bytes32 _contractTerms,
    //     Notary.DomainSeparator memory _domainSeparator
    // ) public virtual returns (bytes memory _signature) {
    //     // Create message for signing
    //     bytes32 _message = Notary.typeDataHash(
    //         ILoanNotary.ContractParams({
    //             principal: _principal,
    //             contractTerms: _contractTerms,
    //             collateralAddress: _collateralAddress,
    //             collateralId: _collateralId,
    //             collateralNonce: _collateralNonce
    //         }),
    //         _domainSeparator
    //     );

    //     // Sign borrower's terms
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPrivKey, _message);
    //     _signature = abi.encodePacked(r, s, v);
    // }

    // function initContract(
    //     uint256 _debtId,
    //     bytes32 _contractTerms,
    //     bytes memory _signature
    // ) public virtual returns (bool _success, bytes memory _data) {
    //     // Create loan contract
    //     vm.startPrank(lender);
    //     (_success, _data) = address(loanContract).call{value: _PRINCIPAL_}(
    //         abi.encodeWithSignature(
    //             "initContract(uint256,bytes32,bytes)",
    //             _debtId,
    //             _contractTerms,
    //             _signature
    //         )
    //     );

    //     vm.stopPrank();

    //     _data = abi.encodePacked(_data);
    // }

    // function initContract(
    //     uint256 _debtId,
    //     uint256 _principal,
    //     bytes32 _contractTerms,
    //     bytes memory _signature
    // ) public virtual returns (bool _success, bytes memory _data) {
    //     // Create loan contract
    //     vm.deal(lender, _principal + (1 ether));
    //     vm.startPrank(lender);
    //     (_success, _data) = address(loanContract).call{value: _principal}(
    //         abi.encodeWithSignature(
    //             "initContract(uint256,bytes32,bytes)",
    //             _debtId,
    //             _contractTerms,
    //             _signature
    //         )
    //     );
    //     vm.stopPrank();

    //     _data = abi.encodePacked(_data);
    // }

    // function initContract(
    //     uint256 _principal,
    //     address _collateralAddress,
    //     uint256 _collateralId,
    //     bytes32 _contractTerms,
    //     bytes memory _signature
    // ) public virtual returns (bool _success, bytes memory _data) {
    //     // Create loan contract
    //     vm.deal(lender, _principal);
    //     vm.startPrank(lender);

    //     (_success, _data) = address(loanContract).call{value: _principal}(
    //         abi.encodeWithSignature(
    //             "initContract(address,uint256,bytes32,bytes)",
    //             _collateralAddress,
    //             _collateralId,
    //             _contractTerms,
    //             _signature
    //         )
    //     );

    //     vm.stopPrank();

    //     _data = abi.encodePacked(_data);
    // }

    // function createLoanContract(
    //     uint256 _collateralId
    // ) public virtual returns (bool, bytes memory) {
    //     bytes32 _contractTerms = createContractTerms();

    //     uint256 _collateralNonce = loanContract.collateralNonce(
    //         address(demoToken),
    //         _collateralId
    //     );

    //     bytes memory _signature = createContractSignature(
    //         _PRINCIPAL_,
    //         _collateralId,
    //         _collateralNonce,
    //         _contractTerms
    //     );

    //     return
    //         initContract(
    //             _PRINCIPAL_,
    //             address(demoToken),
    //             _collateralId,
    //             _contractTerms,
    //             _signature
    //         );
    // }

    // function createLoanContract(
    //     uint256 _collateralId,
    //     ContractTerms memory _terms
    // ) public virtual returns (bool, bytes memory) {
    //     uint256 _collateralNonce = loanContract.collateralNonce(
    //         address(demoToken),
    //         _collateralId
    //     );

    //     return createLoanContract(_collateralId, _collateralNonce, _terms);
    // }

    // function createLoanContract(
    //     uint256 _collateralId,
    //     uint256 _collateralNonce,
    //     ContractTerms memory _terms
    // ) public virtual returns (bool, bytes memory) {
    //     bytes32 _contractTerms = createContractTerms(_terms);

    //     bytes memory _signature = createContractSignature(
    //         _terms.principal,
    //         _collateralId,
    //         _collateralNonce,
    //         _contractTerms
    //     );

    //     return
    //         initContract(
    //             _terms.principal,
    //             address(demoToken),
    //             _collateralId,
    //             _contractTerms,
    //             _signature
    //         );
    // }

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
