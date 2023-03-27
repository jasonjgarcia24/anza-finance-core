const fs = require('fs');
const config = require('../config');
const server_config = require('../server/config');

const { reset } = require("../test/resetFork");
const { impersonate } = require("../test/impersonate");
const { deploy } = require('./deploy');
const { demoMint } = require('./demoMint');

const main = async () => {
  // MAINNET fork setup
  await reset();
  await impersonate();
  provider = new ethers.providers.Web3Provider(network.provider);
  [, borrower, ..._] = await ethers.getSigners();

  // Establish NFT identifiers
  tokenContract = new ethers.Contract(
    config.TRANSFERIBLES[0].nft, config.TRANSFERIBLES[0].abi, borrower
  );
  tokenId = config.TRANSFERIBLES[0].tokenId;

  // Create LoanProposal for NFT
  const deployObj = await deploy(tokenContract, true);

  // Mint DemoToken
  const demoTokens = await demoMint();

  // Build and write config.json output
  fs.writeFileSync(
    './anza/src/config.json',
    JSON.stringify({
      ...config, ...server_config, ...deployObj, ...demoTokens
    }, null, 2)
  );
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

runMain();