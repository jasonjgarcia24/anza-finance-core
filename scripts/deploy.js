const { ethers } = require("hardhat");
const { loanPrincipal, loanFixedInterestRate, loanDuration } = require("../config");
const { listenerLoanContractCreated } = require("../utils/listenersLoanContractFactory");

const deploy = async (tokenContract, tokenId) => {
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

  // * contracts/social/libraries/LibContractTreasurer.sol:LibLoanTreasurey
  const LibLoanTreasureyFactory = await ethers.getContractFactory("LibLoanTreasurey", {
    libraries: {
      TreasurerUtils: TreasurerUtils.address,
      StateControlUint: StateControlUint.address
    },
  });
  const LibLoanTreasurey = await LibLoanTreasureyFactory.deploy();
  
  
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


  /**
   * LoanContractFactory, LoanContract, LoanTreasurey, LoanCollection
   * 
   */
  let [, borrower,,, treasurer, ..._] = await ethers.getSigners();

  const loanCollectionFactory = await ethers.getContractFactory("LoanCollection");
  const loanCollection = await loanCollectionFactory.deploy(treasurer.address);

  const loanTreasureyFactory = await ethers.getContractFactory("LoanTreasurey", {
    libraries: {
      LibLoanTreasurey: LibLoanTreasurey.address,
    }
  });
  const loanTreasurey = await loanTreasureyFactory.deploy(treasurer.address);

  const Factory = await ethers.getContractFactory("LoanContractFactory");
  const loanContractFactory = await Factory.deploy(loanTreasurey.address);

  const LoanContractFactory = await ethers.getContractFactory("LoanContract", {
    libraries: {
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
      StateControlBool: StateControlBool.address,
      LibContractActivate: LibContractActivate.address,
      LibContractInit: LibContractInit.address,
      LibContractUpdate: LibContractUpdate.address,
      LibContractNotary: LibContractNotary.address,
      LibContractScheduler: LibContractScheduler.address,
      LibContractCollector: LibContractCollector.address,
      ERC20Transactions: ERC20Transactions.address,
      ERC721Transactions: ERC721Transactions.address,
      LibLoanTreasurey: LibLoanTreasurey.address,
    },
  });
  loanContract = await LoanContractFactory.deploy();
  await loanContract.deployed();

  // Set loanContract to operator
  await tokenContract.setApprovalForAll(loanContractFactory.address, true);

  let _tx = await loanContractFactory.connect(borrower).createLoanContract(
    loanContract.address,
    loanTreasurey.address,
    loanCollection.address,
    tokenContract.address,
    tokenId,
    loanPrincipal,
    loanFixedInterestRate,
    loanDuration
  );
  let [clone, ...__] = await listenerLoanContractCreated(_tx, loanContractFactory);

  // Connect loanContract
  loanContract = await ethers.getContractAt("LoanContract", clone, borrower);

  return {
      loanContractFactory: loanContractFactory,
      loanContract: loanContract,
      loanTreasurey: loanTreasurey,
      loanCollection: loanCollection,
      StateControlUint: StateControlUint,
      StateControlAddress: StateControlAddress,
      StateControlBool: StateControlBool,
      BlockTime: BlockTime,
      LibContractActivate: LibContractActivate,
      LibContractInit: LibContractInit,
      LibContractUpdate: LibContractUpdate,
      LibContractNotary: LibContractNotary,
      LibContractScheduler: LibContractScheduler,
      LibContractCollector: LibContractCollector,
      LibLoanTreasurey: LibLoanTreasurey,
      TreasurerUtils: TreasurerUtils,
      ERC20Transactions: ERC20Transactions,
      ERC721Transactions: ERC721Transactions
  }
}

module.exports = { deploy };
