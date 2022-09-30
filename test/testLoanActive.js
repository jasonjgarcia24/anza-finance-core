const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES, ROLES, LOANSTATE } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { deploy } = require("../scripts/deploy");
const { listenerLoanActivated } = require("../utils/listenersLoanContract");
const { listenerLoanContractCreated } = require("../utils/listenersLoanContractFactory");
const { listenerTermsChanged } = require("../utils/listenersAContractManager");
const { listenerLoanStateChanged } = require("../utils/listenersAContractGlobals");
const { listenerDeposited, listenerWithdrawn } = require("../utils/listenersAContractTreasurer");

let provider;

let StateControlUint;
let StateControlAddress;
let StateControlBool;
let BlockTime;
let LibContractActivate;
let LibContractInit;
let LibContractUpdate;
let LibContractNotary;
let LibContractScheduler;
let ERC20Transactions;
let ERC721Transactions;

let loanContractFactory, loanContract, loanTreasurey;
let borrower, lender, lenderAlt, admin;
let tokenContract, tokenId;

const loanPrincipal = ethers.utils.parseEther('0.0001');
const loanFixedInterestRate = 23;
const loanDuration = 30;

describe("0 :: LoanContract initialization tests", function () {
  /* NFT and LoanProposal setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [borrower, lender, lenderAlt, admin, ..._] = await ethers.getSigners();

    // Establish NFT identifiers
    tokenContract = new ethers.Contract(
      TRANSFERIBLES[0].nft, TRANSFERIBLES[0].abi, borrower
    );
    tokenId = TRANSFERIBLES[0].tokenId;

    // Create LoanProposal for NFT
    [
      StateControlUint,
      StateControlAddress,
      StateControlBool,
      BlockTime,
      LibContractActivate,
      LibContractInit,
      LibContractUpdate,
      LibContractNotary,
      LibContractScheduler,
      ERC20Transactions,
      ERC721Transactions
     ] = await deploy();

    const loanTreasureyFactory = await ethers.getContractFactory("LoanTreasurey");
    loanTreasurey = await loanTreasureyFactory.deploy();

    const Factory = await ethers.getContractFactory("LoanContractFactory");
    loanContractFactory = await Factory.deploy(loanTreasurey.address);

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
        ERC20Transactions: ERC20Transactions.address,
        ERC721Transactions: ERC721Transactions.address
      },
    });
    loanContract = await LoanContractFactory.deploy();
    await loanContract.deployed();

    // Set loanContract to operator
    await tokenContract.setApprovalForAll(loanContractFactory.address, true);

    let _tx = await loanContractFactory.connect(borrower).createLoanContract(
      loanContract.address,
      loanTreasurey.address,
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
    let [_clone, _tokenContractAddress, _tokenId, _borrower] = await listenerLoanContractCreated(_tx, loanContractFactory);

    // Connect loanContract
    loanContract = await ethers.getContractAt("LoanContract", _clone, borrower);    
  });

  it("0-1-99 :: PASS", async function () {});

  it("0-1-00 :: Verify loan maturity", async function () {
    // Sign lender and activate loan
    let _tx = await loanContract.connect(lender).setLender({ value: loanPrincipal });

    // Advance block number
    // console.log(await provider.getBlockNumber())
    // await advanceBlock(loanDuration);
    // console.log(await provider.getBlockNumber())

    await loanTreasurey.checkMaturity(loanContract.address);
  });
});

const advanceBlock = async (days) => {  
  let _blocks = await BlockTime.daysToBlocks(days);
  _blocks = _blocks.toNumber();
  _blocks = `0x${_blocks.toString(16)}`;

  await network.provider.send("hardhat_mine", [_blocks]);
}
