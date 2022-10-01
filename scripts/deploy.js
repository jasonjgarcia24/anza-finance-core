const { ethers } = require("hardhat");

const deploy = async () => {
  // * contracts/utils/StateControl.sol:StateControlUtils
  const StateControlUtilsFactory = await ethers.getContractFactory("StateControlUtils");
  const StateControlUtils = await StateControlUtilsFactory.deploy();

  // * contracts/utils/StateControl.sol:StateControlUint
  const StateControlUintFactory = await ethers.getContractFactory("StateControlUint", {
    libraries: {
      StateControlUtils: StateControlUtils.address
    }
  });
  const StateControlUint = await StateControlUintFactory.deploy();

  // * contracts/utils/StateControl.sol:StateControlAddress
  const StateControlAddressFactory = await ethers.getContractFactory("StateControlAddress", {
    libraries: {
      StateControlUtils: StateControlUtils.address
    }
  });
  const StateControlAddress = await StateControlAddressFactory.deploy();

  // * contracts/utils/StateControl.sol:StateControlBool
  const StateControlBoolFactory = await ethers.getContractFactory("StateControlBool", {
    libraries: {
      StateControlUtils: StateControlUtils.address
    }
  });
  const StateControlBool = await StateControlBoolFactory.deploy();

  // * contracts/utils/BlockTime.sol:BlockTime
  const BlockTimeFactory = await ethers.getContractFactory("BlockTime");
  const BlockTime = await BlockTimeFactory.deploy();

  // * contracts/social/libraries/LibContractMaster.sol:LibContractActivate
  const LibContractActivateFactory = await ethers.getContractFactory("LibContractActivate", {
    libraries: {
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
    },
  });
  const LibContractActivate = await LibContractActivateFactory.deploy();

  // * contracts/social/libraries/LibContractMaster.sol:LibContractInit
  const LibContractInitFactory = await ethers.getContractFactory("LibContractInit", {
    libraries: {
      BlockTime: BlockTime.address,
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
      StateControlBool: StateControlBool.address,
    },
  });
  const LibContractInit = await LibContractInitFactory.deploy();
  
  // * contracts/social/libraries/LibContractMaster.sol:LibContractUpdate
  const LibContractUpdateFactory = await ethers.getContractFactory("LibContractUpdate", {
    libraries: {
      BlockTime: BlockTime.address,
      StateControlUint: StateControlUint.address,
    },
  });
  const LibContractUpdate = await LibContractUpdateFactory.deploy();
  
  // * contracts/social/libraries/LibContractNotary.sol:LibContractNotary
  const LibContractNotaryFactory = await ethers.getContractFactory("LibContractNotary", {
    libraries: {
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
      StateControlBool: StateControlBool.address,
    },
  });
  const LibContractNotary = await LibContractNotaryFactory.deploy();
    
  // * contracts/social/libraries/LibContractScheduler.sol:LibContractScheduler
  const LibContractSchedulerFactory = await ethers.getContractFactory("LibContractScheduler", {
    libraries: {
      StateControlUint: StateControlUint.address,
    },
  });
  const LibContractScheduler = await LibContractSchedulerFactory.deploy();
    
  // * contracts/social/libraries/LibContractCollections.sol:LibContractCollector
  const LibContractCollectorFactory = await ethers.getContractFactory("LibContractCollector", {
    libraries: {
      // StateControlUint: StateControlUint.address,
    },
  });
  const LibContractCollector = await LibContractCollectorFactory.deploy();

    // * contracts/social/libraries/LibContractTreasurer.sol:TreasurerUtils
    const TreasurerUtilsFactory = await ethers.getContractFactory("TreasurerUtils", {
      libraries: {
        BlockTime: BlockTime.address
      },
    });
    const TreasurerUtils = await TreasurerUtilsFactory.deploy();
  
  
  // * contracts/social/libraries/LibContractTreasurer.sol:ERC20Transactions
  const ERC20TransactionsFactory = await ethers.getContractFactory("ERC20Transactions", {
    libraries: {
      TreasurerUtils: TreasurerUtils.address,
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
    },
  });
  const ERC20Transactions = await ERC20TransactionsFactory.deploy();
  
  // * contracts/social/libraries/LibContractTreasurer.sol:ERC721Transactions
  const ERC721TransactionsFactory = await ethers.getContractFactory("ERC721Transactions");
  const ERC721Transactions = await ERC721TransactionsFactory.deploy();
  
  return [
      StateControlUint,
      StateControlAddress,
      StateControlBool,
      BlockTime,
      LibContractActivate,
      LibContractInit,
      LibContractUpdate,
      LibContractNotary,
      LibContractScheduler,
      LibContractCollector,
      TreasurerUtils,
      ERC20Transactions,
      ERC721Transactions
  ]
}

module.exports = { deploy };
