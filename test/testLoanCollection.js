const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const {
    TRANSFERIBLES, ROLES, LOANSTATE,
    loanPrincipal, loanFixedInterestRate, loanDuration
} = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { deploy } = require("../scripts/deploy");
const { listenerLoanActivated } = require("../utils/listenersLoanContract");
const { listenerLoanContractCreated } = require("../utils/listenersLoanContractFactory");
const { listenerTermsChanged } = require("../utils/listenersAContractManager");
const { listenerLoanStateChanged } = require("../utils/listenersAContractGlobals");
const { listenerDeposited, listenerWithdrawn } = require("../utils/listenersAContractTreasurer");

let provider;

let BlockTime;
let loanContractFactory, loanContract, loanTreasurey, loanCollection;
let owner, borrower, lender, lenderAlt, treasurer;
let tokenContract, tokenId;

describe("0-2 :: LoanContract initialization tests", function () {
  /* NFT and LoanProposal setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [owner, borrower, lender, lenderAlt, treasurer, ..._] = await ethers.getSigners();

    // Establish NFT identifiers
    tokenContract = new ethers.Contract(
      TRANSFERIBLES[0].nft, TRANSFERIBLES[0].abi, borrower
    );
    tokenId = TRANSFERIBLES[0].tokenId;

    // Create LoanProposal for NFT
    ({
      loanContractFactory,
      loanContract,
      loanTreasurey,
      loanCollection,
      BlockTime
    } = await deploy(tokenContract, tokenId));   
  });

  it("0-2-99 :: PASS", async function () {});

  it("x-2-00 :: Verify loan not default when paid", async function () {
    // // Sign lender and activate loan
    // await loanContract.connect(lender).setLender({ value: loanPrincipal });
    // await loanContract.connect(borrower).makePayment({ value: loanPrincipal });

    // // Advance block number
    // await advanceBlock(loanDuration);

    // // Assess maturity
    // let _tx = await loanTreasurey.connect(treasurer).assessMaturity(loanContract.address);
    // let _state = (await loanContract.loanGlobals())['state'];
    // expect(_state).to.equal(LOANSTATE.PAID, "The loan state should be PAID.");
    
    // await expect(
    //   listenerLoanStateChanged(_tx, loanContract)
    // ).to.be.rejectedWith(/Cannot read properties of undefined/);

    // await assert.eventually.isTrue(
    //   loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
    //   "The borrower is not set with PARTICIPANT_ROLE role."
    // );
    // await assert.eventually.isTrue(
    //   loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
    //   "The borrower is not set with COLLATERAL_OWNER_ROLE role."
    // );
    // await assert.eventually.isFalse(
    //   loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, loanContract.address),
    //   "The loan contract is set with COLLATERAL_OWNER_ROLE role."
    // );
  });
});

const advanceBlock = async (days) => {  
  let _blocks = await BlockTime.daysToBlocks(days);
  _blocks = _blocks.toNumber();
  _blocks = `0x${_blocks.toString(16)}`;

  await network.provider.send("hardhat_mine", [_blocks]);
}
