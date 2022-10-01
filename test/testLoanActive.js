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

describe("0-1 :: LoanContract initialization tests", function () {
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
      BlockTime
    } = await deploy(tokenContract, tokenId));   
  });

  it("0-1-99 :: PASS", async function () {});

  it("0-1-00 :: Verify loan default", async function () {
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
      "The borrower is not set with PARTICIPANT_ROLE role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_OWNER_ROLE role."
    );
    await assert.eventually.isFalse(
      loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, loanContract.address),
      "The loan contract is set with COLLATERAL_OWNER_ROLE role."
    );

    // Sign lender and activate loan
    await loanContract.connect(lender).setLender({ value: loanPrincipal });

    // Advance block number
    await advanceBlock(loanDuration);

    // Assess maturity
    let _tx = await loanTreasurey.connect(treasurer).assessMaturity(loanContract.address);
    let _state = (await loanContract.loanGlobals())['state'];
    expect(_state).to.equal(LOANSTATE.DEFAULT, "The new loan state should be DEFAULT.");

    // let [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract);
    // expect(_prevLoanState).to.be.within(LOANSTATE.FUNDED, LOANSTATE.ACTIVE_OPEN, "The previous loan state should be within FUNDED and ACTIVE_OPEN.");
    // expect(_newLoanState).to.equal(LOANSTATE.DEFAULT, "The new loan state should be DEFAULT.");

    // await assert.eventually.isFalse(
    //   loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
    //   "The borrower is set with PARTICIPANT_ROLE role."
    // );
    // await assert.eventually.isFalse(
    //   loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
    //   "The borrower is set with COLLATERAL_OWNER_ROLE role."
    // );
    // await assert.eventually.isTrue(
    //   loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, loanContract.address),
    //   "The loan contract is not set with COLLATERAL_OWNER_ROLE role."
    // );
  });

  it("0-1-01 :: Verify loan not default when paid", async function () {
    // Sign lender and activate loan
    await loanContract.connect(lender).setLender({ value: loanPrincipal });
    await loanContract.connect(borrower).makePayment({ value: loanPrincipal });

    // Advance block number
    await advanceBlock(loanDuration);

    // Assess maturity
    let _tx = await loanTreasurey.connect(treasurer).assessMaturity(loanContract.address);
    let _state = (await loanContract.loanGlobals())['state'];
    expect(_state).to.equal(LOANSTATE.PAID, "The loan state should be PAID.");
    
    await expect(
      listenerLoanStateChanged(_tx, loanContract)
    ).to.be.rejectedWith(/Cannot read properties of undefined/);

    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
      "The borrower is not set with PARTICIPANT_ROLE role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_OWNER_ROLE role."
    );
    await assert.eventually.isFalse(
      loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, loanContract.address),
      "The loan contract is set with COLLATERAL_OWNER_ROLE role."
    );
  });

  it("0-1-02 :: Verify loan balance accrual rate", async function () {
    await loanContract.connect(lender).setLender({ value: loanPrincipal });

    // Advance block number
    let _advanceDuration = 10;
    await advanceBlock(_advanceDuration);

    // Allow update loan balance
    await loanTreasurey.connect(treasurer).updateBalance(loanContract.address);
    let _updatedBalance = (await loanContract.loanProperties())['balance']['_value'];
    expect(_updatedBalance).to.equal(
      getExpectedBalance(_advanceDuration),
      `The expected balance should be ${getExpectedBalance()}.`
    );
  });

  it("0-1-03 :: Verify loan balance update disallowed", async function () {
    await loanContract.connect(lender).setLender({ value: loanPrincipal });

    // Disallow update loan balance by non treasurer
    await expect(
      loanTreasurey.connect(lender).updateBalance(loanContract.address)
    ).to.be.rejectedWith(/Ownable: caller is not the owner/);

    // Pay off loan
    await loanContract.connect(borrower).makePayment({ value: loanPrincipal });
    let _loanBalance = (await loanContract.loanProperties())['balance']['_value']
    expect(_loanBalance).to.equal(0, "The loan balance should be 0.");

    // Advance block number
    let _advanceDuration = 10;
    await advanceBlock(_advanceDuration);

    // Disallow update loan balance by non treasurer
    await expect(
      loanTreasurey.connect(treasurer).updateBalance(loanContract.address)
    ).to.be.rejectedWith(/Loan state must between FUNDED and PAID exclusively./);
  });
});

const advanceBlock = async (days) => {  
  let _blocks = await BlockTime.daysToBlocks(days);
  _blocks = _blocks.toNumber();
  _blocks = `0x${_blocks.toString(16)}`;

  await network.provider.send("hardhat_mine", [_blocks]);
}

const getExpectedBalance = (_loanDuration=loanDuration) => {
  return parseInt(loanPrincipal) + Math.floor((parseInt(loanPrincipal) * _loanDuration/365) * loanFixedInterestRate/100);

}
