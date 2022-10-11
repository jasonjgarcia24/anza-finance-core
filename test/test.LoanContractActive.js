const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES, ROLES, LOANSTATE, DEFAULT_TEST_VALUES } = require("../config");

const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { deploy } = require("../scripts/deploy");
const { listenerLoanActivated } = require("../anza/src/utils/events/listenersLoanContract");
const { listenerLoanContractCreated } = require("../anza/src/utils/events/listenersLoanContractFactory");
const { listenerTermsChanged } = require("../anza/src/utils/events/listenersAContractManager");
const { listenerLoanStateChanged } = require("../anza/src/utils/events/listenersAContractGlobals");
const { listenerDeposited, listenerWithdrawn } = require("../anza/src/utils/events/listenersAContractTreasurer");

let provider;

let BlockTime;
let LoanContractFactory, LoanContract, LoanTreasurey, LoanCollection;
let owner, borrower, lender, lenderAlt, treasurer;
let tokenContract, tokenId;

const loanPrincipal = DEFAULT_TEST_VALUES.PRINCIPAL;
const loanFixedInterestRate = DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE;
const loanDuration = DEFAULT_TEST_VALUES.DURATION;

describe("0-1 :: LoanContract initialization tests", async function () {
  /* NFT and LoanProposal setup */
  beforeEach(async function () {
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
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
    let [clone, ...__] = await listenerLoanContractCreated(_tx, LoanContractFactory);
  
    // Activate LoanContract
    LoanContract = await ethers.getContractAt("LoanContract", clone, borrower);
    _tx = await LoanContract.connect(lender).setLender({ value: loanPrincipal });
    await _tx.wait();
  })

  it("0-1-99 :: PASS", async function () {});

  it("0-1-00 :: Verify LoanContract initializer", async function () {
    specify("Verify roles", async function () {
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._ADMIN_ROLE_, LoanContract.address),
        "The loan contract is not set with ADMIN role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._TREASURER_ROLE_, LoanTreasurey.address),
        "The loan contract is not set with TREASURER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLECTOR_ROLE_, LoanCollection.address),
        "The loan contract is not set with COLLECTOR role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._ARBITER_ROLE_, LoanContract.address),
        "The loan contract is not set with ARBITER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._BORROWER_ROLE_, borrower.address),
        "The borrower is not set with BORROWER role."
      );
      await assert.eventually.isFalse(
        LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
        "The loan contract is set with COLLATERAL_OWNER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, LoanContract.address),
        "The loan contract is set with COLLATERAL_CUSTODIAN role."
      );
      await assert.eventually.isFalse(
        LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, borrower.address),
        "The borrower is set with COLLATERAL_CUSTODIAN role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
        "The borrower is not set with PARTICIPANT role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
        "The borrower is not set with COLLATERAL_OWNER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, LoanContract.address),
        "The loan contract is not set with COLLATERAL_CUSTODIAN role."
      );
    });
  })

  it("0-1-01 :: Verify LoanContract default", async function () {
    await assert.eventually.isTrue(
      LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
      "The borrower is not set with PARTICIPANT_ROLE role."
    );
    await assert.eventually.isTrue(
      LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_OWNER_ROLE role."
    );
    await assert.eventually.isFalse(
      LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
      "The loan contract is set with COLLATERAL_OWNER_ROLE role."
    );

    // Sign lender and activate loan
    await LoanContract.connect(lender).setLender({ value: loanPrincipal });

    // Advance block number
    await advanceBlock(loanDuration);

    // Assess maturity
    let _tx = await LoanTreasurey.connect(treasurer).assessMaturity(LoanContract.address);
    let _state = (await LoanContract.loanGlobals())['state'];
    expect(_state).to.equal(LOANSTATE.DEFAULT, "The new loan state should be DEFAULT.");

    // let [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, LoanContract);
    // expect(_prevLoanState).to.be.within(LOANSTATE.FUNDED, LOANSTATE.ACTIVE_OPEN, "The previous loan state should be within FUNDED and ACTIVE_OPEN.");
    // expect(_newLoanState).to.equal(LOANSTATE.DEFAULT, "The new loan state should be DEFAULT.");

    // await assert.eventually.isFalse(
    //   LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
    //   "The borrower is set with PARTICIPANT_ROLE role."
    // );
    // await assert.eventually.isFalse(
    //   LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
    //   "The borrower is set with COLLATERAL_OWNER_ROLE role."
    // );
    // await assert.eventually.isTrue(
    //   LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
    //   "The loan contract is not set with COLLATERAL_OWNER_ROLE role."
    // );
  });

  it("0-1-02 :: Verify loan not default when paid", async function () {
    // Sign lender and activate loan
    await LoanContract.connect(lender).setLender({ value: loanPrincipal });
    await LoanContract.connect(borrower).makePayment({ value: loanPrincipal });

    // Advance block number
    await advanceBlock(loanDuration);

    // Assess maturity
    let _tx = await LoanTreasurey.connect(treasurer).assessMaturity(LoanContract.address);
    let _state = (await LoanContract.loanGlobals())['state'];
    expect(_state).to.equal(LOANSTATE.PAID, "The loan state should be PAID.");
    
    await expect(
      listenerLoanStateChanged(_tx, LoanContract)
    ).to.be.rejectedWith(/Cannot read properties of undefined/);

    await assert.eventually.isTrue(
      LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
      "The borrower is not set with PARTICIPANT_ROLE role."
    );
    await assert.eventually.isTrue(
      LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_OWNER_ROLE role."
    );
    await assert.eventually.isFalse(
      LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
      "The loan contract is set with COLLATERAL_OWNER_ROLE role."
    );
  });

  it("0-1-03 :: Verify loan balance accrual rate", async function () {
    await LoanContract.connect(lender).setLender({ value: loanPrincipal });

    // Advance block number
    let _advanceDuration = 10;
    await advanceBlock(_advanceDuration);

    // Allow update loan balance
    await LoanTreasurey.connect(treasurer).updateBalance(LoanContract.address);
    let _updatedBalance = (await LoanContract.loanProperties())['balance']['_value'];
    expect(_updatedBalance).to.equal(
      getExpectedBalance(_advanceDuration),
      `The expected balance should be ${getExpectedBalance()}.`
    );
  });

  it("0-1-04 :: Verify loan balance update disallowed", async function () {
    await LoanContract.connect(lender).setLender({ value: loanPrincipal });

    // Disallow update loan balance by non treasurer
    await expect(
      LoanTreasurey.connect(lender).updateBalance(LoanContract.address)
    ).to.be.rejectedWith(/Ownable: caller is not the owner/);

    // Pay off loan
    await LoanContract.connect(borrower).makePayment({ value: loanPrincipal });
    let _loanBalance = (await LoanContract.loanProperties())['balance']['_value']
    expect(_loanBalance).to.equal(0, "The loan balance should be 0.");

    // Advance block number
    let _advanceDuration = 10;
    await advanceBlock(_advanceDuration);

    // Disallow update loan balance by non treasurer
    await expect(
      LoanTreasurey.connect(treasurer).updateBalance(LoanContract.address)
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
