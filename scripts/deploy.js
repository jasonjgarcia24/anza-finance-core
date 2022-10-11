const { ethers } = require("hardhat");

const deploy = async (tokenContract, addressOnly=false) => {
  // * contracts/utils/StateControl.sol:StateControlUtils
  const StateControlUtils_Factory = await ethers.getContractFactory("StateControlUtils");
  const StateControlUtils = await StateControlUtils_Factory.deploy();

  // * contracts/utils/StateControl.sol:StateControlUint
  const StateControlUint_Factory = await ethers.getContractFactory("StateControlUint", {
    libraries: {
      StateControlUtils: StateControlUtils.address
    }
  });
  const StateControlUint = await StateControlUint_Factory.deploy();

  // * contracts/utils/StateControl.sol:StateControlAddress
  const StateControlAddress_Factory = await ethers.getContractFactory("StateControlAddress", {
    libraries: {
      StateControlUtils: StateControlUtils.address
    }
  });
  const StateControlAddress = await StateControlAddress_Factory.deploy();

  // * contracts/utils/StateControl.sol:StateControlBool
  const StateControlBool_Factory = await ethers.getContractFactory("StateControlBool", {
    libraries: {
      StateControlUtils: StateControlUtils.address
    }
  });
  const StateControlBool = await StateControlBool_Factory.deploy();

  // * contracts/utils/BlockTime.sol:BlockTime
  const BlockTime_Factory = await ethers.getContractFactory("BlockTime");
  const BlockTime = await BlockTime_Factory.deploy();

  // * contracts/social/libraries/LibContractMaster.sol:LibContractActivate
  const LibContractActivate_Factory = await ethers.getContractFactory("LibContractActivate", {
    libraries: {
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
    },
  });
  const LibContractActivate = await LibContractActivate_Factory.deploy();

  // * contracts/social/libraries/LibContractMaster.sol:LibContractInit
  const LibContractInit_Factory = await ethers.getContractFactory("LibContractInit", {
    libraries: {
      BlockTime: BlockTime.address,
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
      StateControlBool: StateControlBool.address,
    },
  });
  const LibContractInit = await LibContractInit_Factory.deploy();
  
  // * contracts/social/libraries/LibContractMaster.sol:LibContractUpdate
  const LibContractUpdate_Factory = await ethers.getContractFactory("LibContractUpdate", {
    libraries: {
      BlockTime: BlockTime.address,
      StateControlUint: StateControlUint.address,
    },
  });
  const LibContractUpdate = await LibContractUpdate_Factory.deploy();
  
  // * contracts/social/libraries/LibContractNotary.sol:LibContractNotary
  const LibContractNotary_Factory = await ethers.getContractFactory("LibContractNotary", {
    libraries: {
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
      StateControlBool: StateControlBool.address,
    },
  });
  const LibContractNotary = await LibContractNotary_Factory.deploy();
    
  // * contracts/social/libraries/LibContractScheduler.sol:LibContractScheduler
  const LibContractScheduler_Factory = await ethers.getContractFactory("LibContractScheduler", {
    libraries: {
      StateControlUint: StateControlUint.address,
    },
  });
  const LibContractScheduler = await LibContractScheduler_Factory.deploy();
    
  // * contracts/social/libraries/LibContractCollections.sol:LibContractCollector
  const LibContractCollector_Factory = await ethers.getContractFactory("LibContractCollector", {
    libraries: {
      // StateControlUint: StateControlUint.address,
    },
  });
  const LibContractCollector = await LibContractCollector_Factory.deploy();

  // * contracts/social/libraries/LibContractTreasurer.sol:TreasurerUtils
  const TreasurerUtils_Factory = await ethers.getContractFactory("TreasurerUtils", {
    libraries: {
      BlockTime: BlockTime.address
    },
  });
  const TreasurerUtils = await TreasurerUtils_Factory.deploy();

  // * contracts/social/libraries/LibContractTreasurer.sol:LibLoanTreasurey
  const LibLoanTreasurey_Factory = await ethers.getContractFactory("LibLoanTreasurey", {
    libraries: {
      TreasurerUtils: TreasurerUtils.address,
      StateControlUint: StateControlUint.address,
      StateControlUtils: StateControlUtils.address
    },
  });
  const LibLoanTreasurey = await LibLoanTreasurey_Factory.deploy();
  
  
  // * contracts/social/libraries/LibContractTreasurer.sol:ERC20Transactions
  const ERC20Transactions_Factory = await ethers.getContractFactory("ERC20Transactions", {
    libraries: {
      TreasurerUtils: TreasurerUtils.address,
      StateControlUint: StateControlUint.address,
      StateControlAddress: StateControlAddress.address,
    },
  });
  const ERC20Transactions = await ERC20Transactions_Factory.deploy();
  
  // * contracts/social/libraries/LibContractTreasurer.sol:ERC721Transactions
  const ERC721Transactions_Factory = await ethers.getContractFactory("ERC721Transactions");
  const ERC721Transactions = await ERC721Transactions_Factory.deploy();

  /**
   * LoanContractFactory, LoanContract, LoanTreasurey, LoanCollection, AnzaDebtToken
   */
   [owner,,,, treasurer, ..._] = await ethers.getSigners();

  const LoanCollection_Factory = await ethers.getContractFactory("LoanCollection");
  const LoanCollection = await LoanCollection_Factory.deploy(treasurer.address);

  const LoanTreasurey_Factory = await ethers.getContractFactory("LoanTreasurey", {
    libraries: {
      LibLoanTreasurey: LibLoanTreasurey.address,
    }
  });
  const LoanTreasurey = await LoanTreasurey_Factory.deploy(treasurer.address);

  const AnzaDebtToken_Factory = await ethers.getContractFactory("AnzaDebtToken");
  const AnzaDebtToken = await AnzaDebtToken_Factory.deploy(
    "ipfs://",
    owner.address,
    LoanTreasurey.address
  );
  await AnzaDebtToken.deployed();
  await LoanTreasurey.connect(treasurer).setDebtTokenAddress(AnzaDebtToken.address);

  const LoanContractFactory_Factory = await ethers.getContractFactory("LoanContractFactory");
  const LoanContractFactory = await LoanContractFactory_Factory.deploy(LoanTreasurey.address, LoanCollection.address);
  
  const LoanContract_Factory = await ethers.getContractFactory("LoanContract", {
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
  LoanContract = await LoanContract_Factory.deploy();
  await LoanContract.deployed();

  // Set LoanContract to operator
  await tokenContract.setApprovalForAll(LoanContractFactory.address, true);

  if (!!addressOnly) {
    return {
        LoanContractFactory: LoanContractFactory.address,
        LoanContract: LoanContract.address,
        AnzaDebtToken: AnzaDebtToken.address,
        LoanTreasurey: LoanTreasurey.address,
        LoanCollection: LoanCollection.address,
        StateControlUint: StateControlUint.address,
        StateControlAddress: StateControlAddress.address,
        StateControlBool: StateControlBool.address,
        BlockTime: BlockTime.address,
        LibContractActivate: LibContractActivate.address,
        LibContractInit: LibContractInit.address,
        LibContractUpdate: LibContractUpdate.address,
        LibContractNotary: LibContractNotary.address,
        LibContractScheduler: LibContractScheduler.address,
        LibContractCollector: LibContractCollector.address,
        LibLoanTreasurey: LibLoanTreasurey.address,
        TreasurerUtils: TreasurerUtils.address,
        ERC20Transactions: ERC20Transactions.address,
        ERC721Transactions: ERC721Transactions.address
    }
  } else {
    return {
        LoanContractFactory: LoanContractFactory,
        LoanContract: LoanContract,
        LoanTreasurey: LoanTreasurey,
        AnzaDebtToken: AnzaDebtToken,
        LoanCollection: LoanCollection,
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
}

module.exports = { deploy };
