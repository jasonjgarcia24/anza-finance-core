import { ethers } from "ethers";
import config from "../config.json";
import { Alchemy, Network } from "alchemy-sdk";
import abi_DemoToken from '../artifacts/DemoToken.sol/DemoToken.json';


export const getOwnedTokens = async (chainId, account) => {
    let ownedNfts;

    switch (chainId) {
        // Sepolia
        case '11155111':
            const alchemy = new Alchemy({
                apiKey: process.env.REACT_APP_ALCHEMY_API_KEY,
                network: Network.ETH_SEPOLIA,
            });

            ({ ownedNfts } = await alchemy.nft.getNftsForOwner(account, { includeFilters: "SPAM" }));
            if (Object.keys(ownedNfts).length === 0) {
                console.log("No tokens owned.");
                return;
            }
        // Localhost
        case '31337':
            const { ethereum } = window;
            const provider = new ethers.providers.Web3Provider(ethereum);

            const DemoToken = new ethers.Contract(
                config[chainId].DemoToken,
                abi_DemoToken.abi,
                provider
            );

            ownedNfts = (await DemoToken.getOwnedTokens(account)).map(tkn => (
                {
                    contract: { address: DemoToken.address.toLowerCase() },
                    tokenId: (ethers.utils.formatEther(tkn) * 10 ** 18).toString()
                }
            ));
    }

    return ownedNfts;
}