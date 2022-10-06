const { ethers } = require("hardhat");
const { listenerMint } = require("../utils/listenersDemoToken");


const demoMint = async () => {
    [, borrower, ..._] = await ethers.getSigners();

    const DemoToken_Factory = await ethers.getContractFactory("DemoToken");
    const DemoToken = await DemoToken_Factory.deploy();
    let tx, ownerAddress, tokenContractAddress, tokenId;
    let tokens = { DEMO_TOKENS: {} };
    tokens.DEMO_TOKENS[String(borrower.address.toLowerCase())] = {
        tokens: {
            address: DemoToken.address,
            tokenId: []
        }
    };

    for (let i = 0; i < 30; i++) {
        tx = await DemoToken.mint(borrower.address);
        await tx.wait();

        [ownerAddress, tokenContractAddress, tokenId] = await listenerMint(tx, DemoToken);
        tokens.DEMO_TOKENS[ownerAddress.toLowerCase()].tokens.tokenId.push(tokenId.toNumber());
    }
    return tokens;
}

module.exports = { demoMint };
