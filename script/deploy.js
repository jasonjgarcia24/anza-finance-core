const { ethers } = require("hardhat");


const deploy = async () => {
  // * contracts/utils/BlockTime.sol:BlockTime
  const BlockTime_Factory = await ethers.getContractFactory("BlockTime");
  const BlockTime = await BlockTime_Factory.deploy();

  // * contracts/utils/LibLoanContractStates.sol:LibLoanContractStates
  const LoanContractStates_Factory = await ethers.getContractFactory("LibLoanContractStates");
  const LibLoanContractStates = await LoanContractStates_Factory.deploy();

  // * contracts/utils/LibLoanContractStates.sol:StateControlUtils
  const StateControlUtils_Factory = await ethers.getContractFactory("StateControlUtils", {
    libraries: {
      // LibLoanContractStates: LibLoanContractStates.address
    }
  });
  const StateControlUtils = await StateControlUtils_Factory.deploy();

  // * contracts/utils/StateControl.sol:StateControlUint256
  const StateControlUint256_Factory = await ethers.getContractFactory("StateControlUint256", {
    libraries: {
      StateControlUtils: StateControlUtils.address
    }
  });
  const StateControlUint256 = await StateControlUint256_Factory.deploy();

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

  // * contracts/libraries/LibLoanContract.sol:LibOfficerRoles
  const LibOfficerRoles_Factory = await ethers.getContractFactory("LibOfficerRoles");
  const LibOfficerRoles = await LibOfficerRoles_Factory.deploy();

  // * contracts/libraries/LibLoanContract.sol:LibLoanContractMetadata
  const LibLoanContractMetadata_Factory = await ethers.getContractFactory("LibLoanContractMetadata");
  const LibLoanContractMetadata = await LibLoanContractMetadata_Factory.deploy();

  // * contracts/libraries/LibLoanContract.sol:LibLoanContractInit
  const LibLoanContractInit_Factory = await ethers.getContractFactory("LibLoanContractInit", {
    libraries: {
      StateControlUint256: StateControlUint256.address,
      StateControlAddress: StateControlAddress.address,
      StateControlBool: StateControlBool.address,
    }
  });
  const LibLoanContractInit = await LibLoanContractInit_Factory.deploy();

  // * contracts/libraries/LibLoanContract.sol:LibLoanContractIndexer
  const LibLoanContractIndexer_Factory = await ethers.getContractFactory("LibLoanContractIndexer");
  const LibLoanContractIndexer = await LibLoanContractIndexer_Factory.deploy();

  /**
   * DemoToken, LoanAdmin, LoanContract
   */
  [owner, admin, treasurer, collector, borrower, lender, alt_account1, alt_account2, alt_account3, alt_account4, ..._] = await ethers.getSigners();

  // Demo Token
  // * contracts/DemoToken.sol:DemoToken
  const DemoToken_Factory = await ethers.getContractFactory("DemoToken");
  const DemoToken = await DemoToken_Factory.connect(borrower).deploy();

  /*
   * Loan Arbiter
   */
  const LoanArbiter_Factory = await ethers.getContractFactory("LoanArbiter", {});
  const LoanArbiter = await LoanArbiter_Factory.deploy(
    admin.address,
    treasurer.address,
    collector.address,
  )

  /**
   * Loan Contract
   */
  const LoanContract_Factory = await ethers.getContractFactory("LoanContract", {
    libraries: {
      LibLoanContractInit: LibLoanContractInit.address,
      // LibLoanContractIndexer: LibLoanContractIndexer.address,
      LibLoanContractStates: LibLoanContractStates.address,
      StateControlUint256: StateControlUint256.address,
      StateControlAddress: StateControlAddress.address,
      StateControlBool: StateControlBool.address,
    }
  });
  const LoanContract = await LoanContract_Factory.deploy(
    admin.address,
    LoanArbiter.address,
    treasurer.address,
    collector.address,
    "www.base_uri.com/",
  );
  await LoanContract.deployed();
  console.log("Loan Contract deployed to: ", LoanContract.address);

  loanContractRole = await LibOfficerRoles._LOAN_CONTRACT_();
  LoanArbiter.connect(admin).grantRole(loanContractRole, LoanContract.address);

  return {
    owner: owner,
    admin: admin,
    treasurer: treasurer,
    collector: collector,
    borrower: borrower,
    lender: lender,
    alt_account1: alt_account1,
    alt_account2: alt_account2,
    alt_account3: alt_account3,
    alt_account4: alt_account4,
    BlockTime: BlockTime,
    LibLoanContractStates: LibLoanContractStates,
    StateControlUtils: StateControlUtils,
    StateControlUint256: StateControlUint256,
    StateControlAddress: StateControlAddress,
    StateControlBool: StateControlBool,
    LibOfficerRoles: LibOfficerRoles,
    LibLoanContractMetadata: LibLoanContractMetadata,
    LibLoanContractInit: LibLoanContractInit,
    LibLoanContractIndexer: LibLoanContractIndexer,
    DemoToken: DemoToken,
    LoanContract: LoanContract,
  }
}

module.exports = { deploy };
