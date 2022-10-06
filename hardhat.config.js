require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
const { BLOCK_NUMBER } = require("./config");

module.exports = {
  solidity: "0.8.17",
  paths: {
    artifacts: `./anza/src/artifacts`,
  },
  defaultNetwork: 'hardhat',
  chainId: 31337,
  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_MAINNET_URL,
        blockNumber: BLOCK_NUMBER
      }
    },
    goerli: {
      url: process.env.ALCHEMY_GOERLI_URL,
      accounts: [process.env.PRIVATE_KEY_01]
    }
  }
};
