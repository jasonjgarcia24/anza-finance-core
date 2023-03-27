require("@nomiclabs/hardhat-ethers");
const { ethers, network } = require("hardhat");
const { TRANSFERIBLES } = require("../config");

async function impersonate(verbose=false) {
    provider = new ethers.providers.Web3Provider(network.provider);

    for (let tr of TRANSFERIBLES) {
        // Start impersonating account
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [tr.ownerAddress],
        });
        consoleLog(`Impersonating ${tr.ownerAddress}`, verbose);

        const signer = provider.getSigner(tr.ownerAddress);

        // Query NFT owner
        let nftContract = new ethers.Contract(tr.nft, tr.abi, signer);
        let tx = await nftContract.ownerOf(tr.tokenId);
        consoleLog(`Prev owner is ${tx}`, verbose);

        // Transfer NFT to new owner
        tx = await nftContract["safeTransferFrom(address,address,uint256)"](
            tr.ownerAddress, tr.recipient, tr.tokenId
        );
        await tx.wait();

        // Query NFT owner
        tx = await nftContract.ownerOf(tr.tokenId);
        consoleLog(`New owner is ${tx}`, verbose);

        // Stop impersonating account
        await network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: [tr.ownerAddress],
        });
        consoleLog("Impersonating stopped", verbose);
    }
};

const consoleLog = (str, verbose) => {
    if (verbose) { console.log(str); }
}

module.exports.impersonate = impersonate;