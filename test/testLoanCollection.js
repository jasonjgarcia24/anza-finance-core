const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES, ROLES, LOANSTATE, DEFAULT_TEST_VALUES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { deploy } = require("../scripts/deploy");
const { listenerLoanActivated } = require("../anza/src/events/utils/listenersLoanContract");
const { listenerLoanContractCreated } = require("../anza/src/events/utils/listenersLoanContractFactory");
const { listenerTermsChanged } = require("../anza/src/events/utils/listenersAContractManager");
const { listenerLoanStateChanged } = require("../anza/src/events/utils/listenersAContractGlobals");
const { listenerDeposited, listenerWithdrawn } = require("../anza/src/events/utils/listenersAContractTreasurer");

let provider;

let BlockTime;
let LoanContractFactory, LoanContract, LoanTreasurey, LoanCollection;
let owner, borrower, lender, lenderAlt, treasurer;
let tokenContract, tokenId;

const loanPrincipal = DEFAULT_TEST_VALUES.PRINCIPAL;
const loanFixedInterestRate = DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE;
const loanDuration = DEFAULT_TEST_VALUES.DURATION;

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
      LoanContractFactory,
      LoanContract,
      LoanTreasurey,
      LoanCollection,
      BlockTime
    } = await deploy(tokenContract));

    let _tx = await LoanContractFactory.connect(borrower).createLoanContract(
      LoanContract.address,
      LoanTreasurey.address,
      LoanCollection.address,
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
    let [clone, ...__] = await listenerLoanContractCreated(_tx, LoanContractFactory);
  
    // Connect LoanContract
    LoanContract = await ethers.getContractAt("LoanContract", clone, borrower);
  });

  it("0-2-99 :: PASS", async function () {});

  it("x-2-00 :: Verify loan not default when paid", async function () {
    // // Sign lender and activate loan
    // await LoanContract.connect(lender).setLender({ value: loanPrincipal });
    // await LoanContract.connect(borrower).makePayment({ value: loanPrincipal });

    // // Advance block number
    // await advanceBlock(loanDuration);

    // // Assess maturity
    // let _tx = await LoanTreasurey.connect(treasurer).assessMaturity(LoanContract.address);
    // let _state = (await LoanContract.loanGlobals())['state'];
    // expect(_state).to.equal(LOANSTATE.PAID, "The loan state should be PAID.");
    
    // await expect(
    //   listenerLoanStateChanged(_tx, LoanContract)
    // ).to.be.rejectedWith(/Cannot read properties of undefined/);

    // await assert.eventually.isTrue(
    //   LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
    //   "The borrower is not set with PARTICIPANT_ROLE role."
    // );
    // await assert.eventually.isTrue(
    //   LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
    //   "The borrower is not set with COLLATERAL_OWNER_ROLE role."
    // );
    // await assert.eventually.isFalse(
    //   LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
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
