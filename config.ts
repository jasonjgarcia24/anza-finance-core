const { ethers } = require("ethers");
const erc721 = require("./anza/src/artifacts/@openzeppelin/contracts/token/ERC721/IERC721.sol/IERC721.json").abi;

module.exports = {
    BLOCK_NUMBER: 15563000,
    TRANSFERIBLES: [
        {
            ownerAddress: "0xf1BCf736a46D41f8a9d210777B3d75090860a665",
            nft: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D",
            tokenId: 7445,
            recipient: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            abi: erc721
        },
        {
            ownerAddress: "0x17331428346E388f32013e6bEc0Aba29303857FD",
            nft: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D",
            tokenId: 2129,
            recipient: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            abi: erc721
        },
        {
            ownerAddress: "0xC4B0D0A7717905d342926958453e0654806850bB",
            nft: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D",
            tokenId: 8695,
            recipient: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            abi: erc721
        }
    ],
    ROLES: {
        _ADMIN_ROLE_: ethers.utils.formatBytes32String("_ADMIN_"),
        _TREASURER_ROLE_: ethers.utils.formatBytes32String("_TREASURER_"),
        _COLLECTOR_ROLE_: ethers.utils.formatBytes32String("_COLLECTOR_"),
        _ARBITER_ROLE_: ethers.utils.formatBytes32String("ARBITER"),
        _BORROWER_ROLE_: ethers.utils.formatBytes32String("BORROWER"),
        _LENDER_ROLE_: ethers.utils.formatBytes32String("LENDER"),
        _PARTICIPANT_ROLE_: ethers.utils.formatBytes32String("PARTICIPANT"),
        _COLLATERAL_OWNER_ROLE_: ethers.utils.formatBytes32String("COLLATERAL_OWNER"),
        _COLLATERAL_APPROVER_ROLE_: ethers.utils.formatBytes32String("COLLATERAL_APPROVER")
    },
    LOANSTATE: {
        UNDEFINED: 0,
        NONLEVERAGED: 1,
        UNSPONSORED: 2,
        SPONSORED: 3,
        FUNDED: 4,
        ACTIVE_GRACE_COMMITTED: 5,
        ACTIVE_GRACE_OPEN: 6,
        ACTIVE_COMMITTED: 7,
        ACTIVE_OPEN: 8,
        PAID: 9,
        DEFAULT: 10,
        AUCTION: 11,
        AWARDED: 12,
        CLOSED: 13
    },
    DEFAULT_TEST_VALUES: {
        PRINCIPAL: ethers.utils.parseEther('0.0008').toNumber(),
        FIXED_INTEREST_RATE: 10,
        DURATION: 360
    },
    CHAINID_TO_NETWORK: {
        '31337': 'LocalHost',
        '1': 'ETH Mainnet',
        '5': 'Goerli'
    },
    IPFS: {
        Addresses: {
            Swarm: [
                "/ip4/0.0.0.0/tcp/4001",
                "/ip6/::/tcp/4001",
                "/ip4/0.0.0.0/udp/4001/quic",
                "/ip6/::/udp/4001/quic"
            ],
            Announce: [],
            AppendAnnounce: [],
            NoAnnounce: [],
            API: "/ip4/127.0.0.1/tcp/5001",
            Gateway: "/ip4/127.0.0.1/tcp/8080",
            API_PORT: "5001",
            GATEWAY_PORT: "8080"
        }
    },
    ETHERSCAN: {
        '31337': "https://etherscan.io/",
        '1': "https://etherscan.io/",
        '5': "https://goerli.etherscan.io/"
    }
}