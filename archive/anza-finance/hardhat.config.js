require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
const { BLOCK_NUMBER } = require("./config");

module.exports = {
  solidity: "0.8.17",
  paths: {
    artifacts: `./anza/src/artifacts`,
  },
  defaultNetwork: 'localhost',
  chainId: 31337,
  networks: {
    hardhat: {
      accounts: [
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_0,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_1,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_2,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_3,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_4,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_5,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_6,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_7,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_8,
          balance: "1000000000000000000000"
        },
        {
          privateKey: process.env.DEAD_ACCOUNT_PRIVATE_KEY_9,
          balance: "500000000000000000000"
        },
      ]
    },
    forking: {
      url: process.env.ALCHEMY_MAINNET_URL,
      blockNumber: BLOCK_NUMBER,
    }
  },
  goerli: {
    url: process.env.ALCHEMY_GOERLI_URL,
    accounts: [process.env.PRIVATE_KEY_01]
  }
}
