const erc721 = require("./artifacts/@openzeppelin/contracts/token/ERC721/IERC721.sol/IERC721.json").abi;

module.exports = {
    BLOCK_NUMBER: 15563000,
    TRANSFERIBLES: [
        {
            ownerAddress: "0xf1BCf736a46D41f8a9d210777B3d75090860a665",
            nft: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D",
            tokenId: 7445,
            recipient: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            abi: erc721
        },
        {
            ownerAddress: "0x17331428346E388f32013e6bEc0Aba29303857FD",
            nft: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D",
            tokenId: 2129,
            recipient: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            abi: erc721
        },
        {
            ownerAddress: "0xC4B0D0A7717905d342926958453e0654806850bB",
            nft: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D",
            tokenId: 8695,
            recipient: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            abi: erc721
        }
    ],    
}