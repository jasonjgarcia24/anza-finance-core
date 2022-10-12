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
let ILoanContract;
let owner, borrower, lender, lenderAlt, treasurer, coBorrower;
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
    [owner, borrower, lender, lenderAlt, treasurer, coBorrower, ..._] = await ethers.getSigners();

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
    ILoanContract = await ethers.getContractAt("ILoanContract", clone, borrower);
    _tx = await LoanContract.connect(lender).setLender({ value: loanPrincipal });
    await _tx.wait();
  })

  it("0-1-99 :: PASS", async function () {});

  it("0-1-00 :: Verify LoanContract initializer", async function () {
    let _state;

    // Verify roles
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._ADMIN_ROLE_, LoanContract.address),
      "The loan contract is not set with ADMIN role."
    );
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._ARBITER_ROLE_, LoanContract.address),
      "The loan contract is not set with ARBITER role."
    );
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
      "The loan contract is not set with COLLATERAL_OWNER role."
    );
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._COLLATERAL_APPROVER_ROLE_, LoanContract.address),
      "The loan contract is set with COLLATERAL_APPROVER role."
    );

    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._TREASURER_ROLE_, LoanTreasurey.address),
      "The loan contract is not set with TREASURER role."
    );
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._COLLECTOR_ROLE_, LoanCollection.address),
      "The loan contract is not set with COLLECTOR role."
    );

    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._BORROWER_ROLE_, borrower.address),
      "The borrower is not set with BORROWER role."
    );
    await assert.eventually.isFalse(
      ILoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_OWNER role."
    );
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._COLLATERAL_APPROVER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_APPROVER role."
    );
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
      "The borrower is not set with PARTICIPANT role."
    );

    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address),
      "The lender is not set with LENDER role."
    );
    await assert.eventually.isTrue(
      ILoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address),
      "The lender is not set with PARTICIPANT role."
    );

    // Verify state
    [,,_state,..._] = await LoanContract.loanGlobals();
    expect(_state).to.equal(LOANSTATE.ACTIVE_OPEN, "The loan state should be ACTIVE_OPEN.");
  })

  it("0-1-01 :: Verify LoanContract NFT withdrawal denied when state is ACTIVE_", async function () {
    await expect(
      LoanContract.connect(borrower).withdrawNft()
    ).to.be.rejectedWith(/Access to change value is denied./);
  });

  it("0-1-02 :: Verify LoanContract payment reflected in balance", async function () {
    let _tx, _prevBalance, _newBalance;
    let _loanPayment = loanPrincipal * 0.25;

    // LoanContract must only allow LoanTreasurer to make payments
    await expect(
      LoanContract.connect(borrower).makePayment({ value: _loanPayment })
    ).to.be.rejectedWith(/AccessControl: account .* is missing role/);

    // Make loan payment with borrower
    [,,,,,, _prevBalance,] = await LoanContract.loanProperties();
    _prevBalance = _prevBalance[0].toNumber();

    _tx = await LoanTreasurey.connect(borrower).makePayment(
      LoanContract.address, { value: _loanPayment }
    );

    [,,,,,, _newBalance,] = await LoanContract.loanProperties();
    _newBalance = _newBalance[0].toNumber();
    [_payee, _weiAmount] = await listenerDeposited(_tx, ILoanContract);

    expect(_prevBalance - _newBalance).to.equal(_loanPayment, "LoanContract payment is not reflected in balance.");
    expect(_payee).to.equal(borrower.address, "Borrower must be the payee.");
    expect(_weiAmount.toNumber()).to.equal(_loanPayment, "Payment amount must match loan payment.");

    // Make LoanContract payment with coBorrower
    [,,,,,, _prevBalance,] = await LoanContract.loanProperties();
    _prevBalance = _prevBalance[0].toNumber();

    _tx = await LoanTreasurey.connect(coBorrower).makePayment(
      LoanContract.address, { value: _loanPayment }
    );

    [,,,,,, _newBalance,] = await LoanContract.loanProperties();
    _newBalance = _newBalance[0].toNumber();
    [_payee, _weiAmount] = await listenerDeposited(_tx, ILoanContract);

    expect(_prevBalance - _newBalance).to.equal(_loanPayment, "LoanContract payment is not reflected in balance.");
    expect(_payee).to.equal(coBorrower.address, "Co-borrower must be the payee.");
    expect(_weiAmount.toNumber()).to.equal(_loanPayment, "Payment amount must match loan payment.");

    // Pay off loan
    await LoanTreasurey.connect(borrower).makePayment(
      LoanContract.address, { value: _loanPayment * 2 }
    );

    [,,,,,, _newBalance,] = await LoanContract.loanProperties();
    _newBalance = _newBalance[0].toNumber();
    expect(_newBalance).to.equal(0, "The loan balance should be 0.");
    
    _state = (await LoanContract.loanGlobals())['state'];
    expect(_state).to.equal(LOANSTATE.PAID, "The loan state should be PAID.");
  });

  it("0-1-03 :: Verify LoanContract default", async function () {
    let _state;

    // Advance block number partially
    await advanceBlock(loanDuration * 0.1);

    // Assess maturity
    await LoanTreasurey.connect(treasurer).assessMaturity(LoanContract.address);
    _state = (await LoanContract.loanGlobals())['state'];
    expect(_state).to.not.equal(LOANSTATE.DEFAULT, "The new loan state should not be DEFAULT.");

    // Advance block number fully
    await advanceBlock(loanDuration * 0.9);

    // Assess maturity
    await LoanTreasurey.connect(treasurer).assessMaturity(LoanContract.address);
    _state = (await LoanContract.loanGlobals())['state'];
    expect(_state).to.equal(LOANSTATE.DEFAULT, "The new loan state should be DEFAULT.");
  });

  it("0-1-04 :: Verify LoanContract not default when paid", async function () {
    let _state;

    // Pay off loan
    await LoanTreasurey.connect(borrower).makePayment(LoanContract.address, { value: loanPrincipal });

    // Advance block number
    await advanceBlock(loanDuration);

    // Assess maturity
    await expect(
      LoanTreasurey.connect(treasurer).assessMaturity(LoanContract.address)
    ).to.be.rejectedWith(/Loan state must between FUNDED and PAID exclusively./);
    _state = (await LoanContract.loanGlobals())['state'];
    expect(_state).to.equal(LOANSTATE.PAID, "The loan state should be PAID.");
  });

  it("0-1-05 :: Verify LoanContract payment denied with status is PAID", async function () {
    // Pay off loan
    await LoanTreasurey.connect(borrower).makePayment(
      LoanContract.address, { value: loanPrincipal }
    );

    // Should fail for StateControl restrictions of setting balance
    await expect(
      LoanTreasurey.connect(borrower).makePayment(
        LoanContract.address, { value: loanPrincipal }
      )
    ).to.be.rejectedWith(/Payment failed./);
  });

  it("0-1-06 :: Verify loan balance accrual rate", async function () {
    let _advanceDuration, _loanPropertiesBalance, _retrievedBalance

    // Advance block number
    _advanceDuration = 10;
    await advanceBlock(_advanceDuration);

    // Allow update loan balance
    _retrievedBalance = await LoanTreasurey.connect(treasurer).getBalance(LoanContract.address);
    expect(_retrievedBalance.toNumber()).to.equal(
      getExpectedBalance(_advanceDuration),
      `The expected balance should be ${getExpectedBalance()}.`
    );

    // LoanContract loanProperties balance should remain unchanged
    [,,,,,, _loanPropertiesBalance,] = await LoanContract.loanProperties();
    expect(_loanPropertiesBalance[0].toNumber()).to.equal(
      loanPrincipal,
      `The expected balance should be ${getExpectedBalance()}.`
    );

    // Update LoanContract loanProperties using `treasurer`
    await LoanTreasurey.connect(treasurer).updateBalance(LoanContract.address);
    [,,,,,, _loanPropertiesBalance,] = await LoanContract.loanProperties();
    expect(_loanPropertiesBalance[0].toNumber()).to.equal(
      _retrievedBalance.toNumber(),
      `The expected balance should be ${getExpectedBalance()}.`
    );
  });

  it("0-1-07 :: Verify loan balance update disallowed", async function () {
    let _advanceDuration = 10;

    // Disallow LoanContract update loan balance by non Treasurey
    await expect(
      LoanContract.connect(treasurer).updateBalance()
    ).to.be.rejectedWith(/AccessControl: account .* is missing role/);

    // Disallow Treasurey update loan balance by non treasurer
    await expect(
      LoanTreasurey.connect(lender).updateBalance(LoanContract.address)
    ).to.be.rejectedWith(/Ownable: caller is not the owner/);

    // Disallow update loan balance on paid off loan
    await LoanTreasurey.connect(borrower).makePayment(LoanContract.address, { value: loanPrincipal });
    await advanceBlock(_advanceDuration);

    await expect(
      LoanTreasurey.connect(treasurer).updateBalance(LoanContract.address)
    ).to.be.rejectedWith(/Access to change value is denied./);
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
