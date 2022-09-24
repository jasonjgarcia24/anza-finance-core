const { assert, expect, should } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { listenerLoanContractCreated } = require("../utils/listenersLoanContractFactory");
const { listenerTermsChanged } = require("../utils/listenersAContractManager");
const { listenerLoanStateChanged } = require("../utils/listenersAContractGlobals");
const { listenerDeposited, listenerWithdrawn } = require("../utils/listenersAContractTreasurer");

const loanState = {
  UNDEFINED: 0,
  NONLEVERAGED: 1,
  UNSPONSORED: 2,
  SPONSORED: 3,
  FUNDED: 4,
  ACTIVE_GRACE_COMMITTED: 5,
  ACTIVE_GRACE_OPEN: 6,
  ACTIVE_COMMITTED: 7,
  ACTIVE_OPEN: 8,
  PAID: 9,
  DEFAULT: 10,
  AUCTION: 11,
  AWARDED: 12,
  CLOSED: 13
};

let provider;
let loanProposal, loanId, loanContract;
let borrower, lender, lenderAlt, approver, operator;
let tokenContract, tokenId;

const loanExpectedPriority = 1;
const loanPrincipal = ethers.utils.parseEther('0.0001');
const loanFixedInterestRate = 23;
const loanDuration = 3;

const _ARBITER_ROLE_ = ethers.utils.formatBytes32String("ARBITER");
const _BORROWER_ROLE_ = ethers.utils.formatBytes32String("BORROWER");
const _LENDER_ROLE_ = ethers.utils.formatBytes32String("LENDER");
const _PARTICIPANT_ROLE_ = ethers.utils.formatBytes32String("PARTICIPANT");
const _COLLATERAL_CUSTODIAN_ROLE_ = ethers.utils.formatBytes32String("COLLATERAL_CUSTODIAN");
const _COLLATERAL_OWNER_ROLE_ = ethers.utils.formatBytes32String("COLLATERAL_OWNER");

describe("0 :: LoanProposal tests", function () {
  /* NFT and LoanProposal setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [borrower, lender, lenderAlt, approver, operator, ..._] = await ethers.getSigners();

    // // Drain borrower account for ethers.js
    // const borrowerWallet = new ethers.Wallet(borrowerPrivateKey, provider);

    // _borrowerBalance = await provider.getBalance(borrower.address);
    // let _tx = {
    //   to: ethers.constants.AddressZero,
    //   value: ethers.utils.parseEther('9999.9')
    // };
    // await borrowerWallet.sendTransaction(_tx);

    // Establish NFT identifiers
    tokenContract = new ethers.Contract(
      TRANSFERIBLES[0].nft, TRANSFERIBLES[0].abi, borrower
    );
    tokenId = TRANSFERIBLES[0].tokenId;

    // Create LoanProposal for NFT
    const LoanProposalFactory = await ethers.getContractFactory("LoanContractFactory");
    loanProposal = await LoanProposalFactory.deploy();
    await loanProposal.deployed();

    // // Set loanProposal to operator
    await tokenContract.setApprovalForAll(loanProposal.address, true);

    let _tx = await loanProposal.connect(borrower).createLoanContract(
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
    let [_loanContractAddress, _tokenContractAddress, _tokenId, _borrower] = await listenerLoanContractCreated(_tx, loanProposal);

    // Connect loanContract
    loanContract = await ethers.getContractAt("LoanContract", _loanContractAddress, borrower);
  });

  it("0-0-99 :: PASS", async function () {});

  it("0-0-00 :: verify constructor", async function () {
    // Verify LoanProposal getter functions
    await expect(loanContract.borrower()).to.eventually.equal(borrower.address, "The borrower address is not correct.");
    await expect(loanContract.lender()).to.eventually.equal(ethers.constants.AddressZero, "The lender address is not correct.");
    await expect(loanContract.tokenContract()).to.eventually.equal(tokenContract.address, "The token contract address is not correct.");
    await expect(loanContract.tokenId()).to.eventually.equal(tokenId, "The token ID is not correct.");
    await expect(loanContract.principal()).to.eventually.equal(loanPrincipal, "The principal is not correct.");
    await expect(loanContract.fixedInterestRate()).to.eventually.equal(loanFixedInterestRate, "The fixed interest rate is not correct.");
    await expect(loanContract.duration()).to.eventually.equal(loanDuration, "The duration is not correct.");
    await assert.eventually.isTrue(loanContract.borrowerSigned() , "The borrower signed status is not correct.");
    await assert.eventually.isFalse(loanContract.lenderSigned(), "The lender signed status is not correct.");

    // Verify roles
    await assert.eventually.isTrue(
      loanContract.hasRole(_ARBITER_ROLE_, loanContract.address),
      "The loan contract is not set with ARBITER role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(_BORROWER_ROLE_, borrower.address),
      "The borrower is not set with BORROWER role."
    );
    await assert.eventually.isFalse(
      loanContract.hasRole(_COLLATERAL_OWNER_ROLE_, loanProposal.address),
      "The loan proposal is set with COLLATERAL_OWNER role."
    );
    await assert.eventually.isFalse(
      loanContract.hasRole(_COLLATERAL_CUSTODIAN_ROLE_, loanProposal.address),
      "The loan proposal is set with COLLATERAL_CUSTODIAN role."
    );
    await assert.eventually.isFalse(
      loanContract.hasRole(_COLLATERAL_CUSTODIAN_ROLE_, borrower.address),
      "The borrower is set with COLLATERAL_CUSTODIAN role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(_PARTICIPANT_ROLE_, borrower.address),
      "The borrower is not set with PARTICIPANT role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(_COLLATERAL_OWNER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_OWNER role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(_COLLATERAL_CUSTODIAN_ROLE_, loanContract.address),
      "The loan contract is not set with COLLATERAL_CUSTODIAN role."
    );
    
    // Verify collateral's owner and approver status
    await expect(tokenContract.ownerOf(tokenId)).to.eventually.equal(
      loanContract.address,
      "The LoanContract must be the token owner."
    );
    await expect(tokenContract.getApproved(tokenId)).to.eventually.equal(
      ethers.constants.AddressZero,
      "There must be no token approver."
    );
  });

  it("0-0-01 :: Test LoanProposal borrower signoffs", async function () {
    // Borrower withdraws LoanContract and LoanContract transfers NFT to borrower
    let _tx = await loanContract.connect(borrower).withdrawNft();
    let [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    let [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    _owner = await tokenContract.ownerOf(tokenId);

    expect(_prevLoanState).to.equal(loanState.UNSPONSORED, "The previous loan state must be UNSPONSORED.");
    expect(_newLoanState).to.equal(loanState.NONLEVERAGED, "The new loan state must be NONLEVERAGED.");
    expect(_owner).to.equal(borrower.address, "The token owner should be the borrower.");
    
    // Borrower signs LoanContract and transfers NFT to LoanProposal
    await tokenContract.setApprovalForAll(loanContract.address, true);
    _tx = await loanContract.connect(borrower).sign();
    [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    _owner = await tokenContract.ownerOf(tokenId);

    expect(_prevLoanState).to.equal(loanState.NONLEVERAGED, "The previous loan state must be NONLEVERAGED.");
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, "The new loan state must be UNSPONSORED.");
    expect(_owner).to.equal(loanContract.address, "The token owner should be the LoanContract.");
  });

  it("0-0-02 :: Test LoanProposal setLender function", async function () {
    // Set lender with lender
    await assert.eventually.isFalse(loanContract.hasRole(_LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
    await assert.eventually.isFalse(loanContract.hasRole(_PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");

    let _tx = await loanContract.connect(lender).setLender({ value: loanPrincipal });
    await assert.eventually.isTrue(loanContract.hasRole(_LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");

    let [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    let [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    let [_payee, _weiAmount] = await listenerDeposited(_tx, loanContract);
    expect(_prevLoanState).to.equal(loanState.UNSPONSORED, "The previous loan state should be UNSPONSORED.");
    expect(_newLoanState).to.equal(loanState.FUNDED, "The new loan state should be FUNDED.");
    expect(_payee).to.equal(lender.address, "The payee should be the lender.");
    expect(_weiAmount.eq(loanPrincipal)).to.equal(true, `The deposited amount should be ${loanPrincipal} WEI.`);

    await assert.eventually.isTrue(loanContract.hasRole(_LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");
    await assert.eventually.isTrue(loanContract.hasRole(_PARTICIPANT_ROLE_, lender.address), "The lender not is set with PARTICIPANT role.");

    // Attempt to steal sponsorship
    await expect(loanContract.connect(lenderAlt).setLender(
      { value: loanPrincipal }
    )).to.be.rejectedWith(/The lender must not currently be signed off./);

    // Remove lender with borrower
    _tx = await loanContract.setLender();
    [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    expect(_prevLoanState).to.equal(loanState.FUNDED, "The previous loan state should be FUNDED.");
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, "The new loan state should be UNSPONSORED.");
    await expect(loanContract.lender()).to.eventually.equal(ethers.constants.AddressZero, "The lender is not set to AddressZero.");
    
    await assert.eventually.isFalse(loanContract.hasRole(_LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
    await assert.eventually.isTrue(loanContract.hasRole(_PARTICIPANT_ROLE_, lender.address), "The lender not is set with PARTICIPANT role.");

    // Remove lender with lender
    await loanContract.connect(lender).setLender();
    _tx = await loanContract.connect(lender).withdrawSponsorship();
    [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    expect(_prevLoanState).to.equal(loanState.FUNDED, "The previous loan state should be FUNDED.");
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, "The new loan state should be UNSPONSORED.");

    await assert.eventually.isFalse(loanContract.hasRole(_LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
    await assert.eventually.isFalse(loanContract.hasRole(_PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");
  });

  it("0-0-03 :: Test LoanProposal updateTerms function for single changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    let [_loanPrincipal, _loanFixedInterestRate, _loanDuration] = await loanContract.getLoanTerms();
    expect(_loanPrincipal).to.equal(loanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanDuration).to.equal(loanDuration, "The loan duration is not set as expected.");

    // Update loan principal
    _tx = await loanContract.updateTerms(['principal'], [_newLoanPrincipal]);
    [_loanPrincipal, _loanFixedInterestRate, _loanDuration] = await loanContract.getLoanTerms();
    expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanDuration).to.equal(loanDuration, "The loan duration is not set as expected.");

    let [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, loanContract);
    expect('principal').to.equal(_params[0], "Emitted event params incorrect.");
    expect(_prevValues[0].toNumber()).to.equal(loanPrincipal, "Emitted event previous principal value incorrect.");
    expect(_newValues[0].toNumber()).to.equal(_newLoanPrincipal, "Emitted event new principal value incorrect.");

    // Update loan fixed interest rate
    _tx = await loanContract.updateTerms(['fixed_interest_rate'], [_newLoanFixedInterestRate]);
    [_loanPrincipal, _loanFixedInterestRate, _loanDuration] = await loanContract.getLoanTerms();
    expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(_newLoanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanDuration).to.equal(loanDuration, "The loan duration is not set as expected.");

    [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, loanContract);
    expect('fixed_interest_rate').to.equal(_params[0], "Emitted event params incorrect.");
    expect(_prevValues[0].toNumber()).to.equal(loanFixedInterestRate, "Emitted event previous fixed interest rate value incorrect.");
    expect(_newValues[0].toNumber()).to.equal(_newLoanFixedInterestRate, "Emitted event new fixed interest rate value incorrect.");

    // Update loan duration
    _tx = await loanContract.updateTerms(['duration'], [_newLoanDuration]);
    [_loanPrincipal, _loanFixedInterestRate, _loanDuration] = await loanContract.getLoanTerms();
    expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(_newLoanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanDuration).to.equal(_newLoanDuration, "The loan duration is not set as expected.");

    [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, loanContract);
    expect('duration').to.equal(_params[0], "Emitted event params incorrect.");
    expect(_prevValues[0].toNumber()).to.equal(loanDuration, "Emitted event previous duration value incorrect.");
    expect(_newValues[0].toNumber()).to.equal(_newLoanDuration, "Emitted event new duration value incorrect.");
  });

  it("0-0-04 :: Test LoanProposal updateTerms function for multiple changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    const _prevLoanTerms = await loanContract.getLoanTerms();
    assert.isTrue(
      _prevLoanTerms[0].eq(loanPrincipal) &&
      _prevLoanTerms[1].eq(loanFixedInterestRate) &&
      _prevLoanTerms[2].eq(loanDuration),
      "Loan terms have been modified."
    );

    // Update all loan parameters
    const _tx = await loanContract.updateTerms(
      ['principal', 'duration', 'fixed_interest_rate'],
      [_newLoanPrincipal, _newLoanDuration, _newLoanFixedInterestRate],
    );

    // Verify loan parameters using getter functions
    const [_loanPrincipal, _loanFixedInterestRate, _loanDuration] = await loanContract.getLoanTerms();

    assert.isTrue(
      _loanPrincipal.eq(_newLoanPrincipal),
      "Loan principal change is not correct."
    );

    assert.isTrue(
      _loanFixedInterestRate.eq(_newLoanFixedInterestRate),
      "Loan fixed interest rate change is not correct."
    );

    assert.isTrue(
      _loanDuration.eq(_newLoanDuration),
      "Loan duration change is not correct."
    );

    // Verify loan parameters using emitted events
    const [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, loanContract);
    expect(_prevValues[0].toNumber()).to.equal(loanPrincipal, "Emitted event previous principal value incorrect.");
    expect(_newValues[0].toNumber()).to.equal(_newLoanPrincipal, "Emitted event new principal value incorrect.");
    expect(_prevValues[2].toNumber()).to.equal(loanFixedInterestRate, "Emitted event previous fixed interest rate value incorrect.");
    expect(_newValues[2].toNumber()).to.equal(_newLoanFixedInterestRate, "Emitted event new fixed interest rate value incorrect.");
    expect(_prevValues[1]).to.equal(loanDuration, "Emitted event previous duration value incorrect.");
    expect(_newValues[1]).to.equal(_newLoanDuration, "Emitted event new duration value incorrect.");
  });

  it("0-0-05 :: Test LoanProposal lender signoffs", async function () {
  //   let _, _prevLoanState, _newLoanState;

  //   // Lender signs LoanProposal via setLender and transfers funds to LoanProposal

  //   let _tx = await loanProposal.connect(lender).setLender(
  //     tokenContract.address, tokenId, loanId, { value: loanPrincipal }
  //   );
  //   [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);

  //   expect(_signer).to.equal(lender.address, "Lender and signer are not the same.");
  //   assert.isTrue(_action.eq(1), "withdraw action is not expected.");
  //   assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
  //   assert.isTrue(_lenderSignStatus, "Lender sign status is not true.");

  //   // Lender withdraws from LoanProposal
  //   _tx = await loanProposal.connect(lender).withdraw(tokenContract.address, tokenId, loanId);
  //   [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);
  //   [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, loanProposal);

  //   expect(_signer).to.equal(lender.address, "Lender and signer are not the same.");
  //   assert.isFalse(_action.eq(1), "Sign action is not expected.");
  //   assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
  //   assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");
    
  //   expect(_prevLoanState).to.equal(loanState.SPONSORED, `Previous loan proposal state should be ${loanState.SPONSORED}.`);
  //   expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);

  //   // Lender cannot signs LoanProposal with sign function
  //   await assert.eventually.throws(
  //     loanProposal.connect(lender).sign(
  //       tokenContract.address, tokenId, loanId, { value: loanPrincipal },
  //       /Only the borrower can sign. If lending, use setLender()/
  //     ),
  //   );
  // });

  // it("0-0-06 :: Test LoanProposal deploy LoanContract", async function () {
  //   let _borrowerBalance = await provider.getBalance(borrower.address);
  //   let _proposalBalance = await provider.getBalance(loanProposal.address);
  //   console.log(`Initial borrower balance: ${_borrowerBalance}`);
  //   console.log(`Initial proposal balance: ${_proposalBalance}`);
  
  //   // Deploy LoanContract by signing off loan proposal
  //   let _tx = await loanProposal
  //     .connect(lender)
  //     .setLender(tokenContract.address, tokenId, loanId, { value: loanPrincipal });
  //   _proposalBalance = await provider.getBalance(loanProposal.address);
  //   console.log(`New proposal balance: ${_proposalBalance}`);

  //   _tx = await loanProposal
  //     .connect(borrower)
  //     .sign(tokenContract.address, tokenId, loanId);      
  //   _borrowerBalance = await provider.getBalance(borrower.address);
  //   _proposalBalance = await provider.getBalance(loanProposal.address);
  //   console.log(`Final borrower balance: ${_borrowerBalance}`);
  //   console.log(`Final proposal balance: ${_proposalBalance}`);

  //   // Test LoanContractDeployed event output
  //   let [_loanContractAddress, _borrowerAddress, _lenderAddress, _tokenContractAddress, _tokenId] = await listenerLoanContractDeployed(_tx, loanProposal);
  //   expect(_borrowerAddress).to.equal(borrower.address, "The borrower address does not match.");
  //   expect(_lenderAddress).to.equal(lender.address, "The lender address does not match.");
  //   expect(_tokenContractAddress).to.equal(tokenContract.address, "The token contract address does not match.");
  //   expect(_tokenId).to.equal(tokenId, "The token ID does not match.");

  //   // Test LoanContract storage values
  //   let loanContract = await ethers.getContractAt("LoanContract", _loanContractAddress);
  //   let results = await getLoanContractStateVars(loanContract.address);
  //   // console.log(`prev prop balance: ${_prevProposalBalance}`)
  //   // console.log(`new prop balance: ${_newProposalBalance}`)
  //   expect(results.borrower).to.equal(borrower.address, "The borrower address does not match.");
  //   expect(results.lender).to.equal(lender.address, "The lender address does not match.");
  //   expect(results.tokenContract).to.equal(tokenContract.address, "The token contract address does not match");
  //   expect(results.tokenId).to.equal(tokenId, "The token ID does not match.");
  //   expect(results.priority).to.equal(loanExpectedPriority, "The priority does not match.");
  //   assert.isTrue(loanPrincipal.eq(results.principal), "The principal does not match.");
  //   expect(results.fixedInterestRate).to.equal(loanFixedInterestRate, "The fixed interest rate does not match.");
  //   expect(results.duration).to.equal(loanDuration, "The duration does not match.");
  //   expect(results.balance).to.equal(0, "The balance does not match.");
  //   // assert.isTrue(_newBorrowerBalance.gt(_prevBorrowerBalance), "The borrower's new balance is not greater than before.");
  //   assert.isTrue(_prevProposalBalance.gt(_newProposalBalance), "The proposals's previous balance is not greater than before.");
  });
});

const updateLender = async (_sender, loanId) => {
  const _tx = await loanProposal.connect(_sender).setLender(
    tokenContract.address, tokenId, loanId, { value: loanPrincipal }
  );

  const [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, loanProposal);
  const [_, _newLender] = await listenerLoanLenderChanged(_tx, loanProposal);

  return [_prevLoanState, _newLoanState, _newLender];
}

const updateLoanParams = async (loanId, _params, _newValues, _prevValues) => {
  const _tx = await loanProposal.setLoanParam(
    tokenContract.address,
    tokenId,
    loanId,
    _params,
    _newValues
  );

  const _newLoanTerms = await loanProposal.getLoanTerms(
    tokenContract.address, tokenId, loanId
  );

  // Check LoanParamChanged event triggered
  const _inputParamHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(_params.at(-1)));
  let [_outputParamHash, _outputPrevValue, _outputNewValue] = await listenerLoanParamChanged(_tx, loanProposal);

  assert.equal(_outputParamHash, _inputParamHash, "param emitted is not correct.");
  assert.equal(_outputPrevValue.toNumber(), _prevValues.at(-1).toNumber(), "prevValue emitted is not correct.");
  assert.equal(_outputNewValue.toNumber(), _newValues.at(-1), "newValue emitted is not correct.");

  return _newLoanTerms;
}

const getLoanContractStateVars = async (_loanContractAddress) => {
  results = {
    borrower: await provider.getStorageAt(_loanContractAddress, 0),
    lender: await provider.getStorageAt(_loanContractAddress, 1),
    tokenContract: await provider.getStorageAt(_loanContractAddress, 2),
    tokenId: await provider.getStorageAt(_loanContractAddress, 3),
    priority: await provider.getStorageAt(_loanContractAddress, 4),
    principal: await provider.getStorageAt(_loanContractAddress, 5),
    fixedInterestRate: await provider.getStorageAt(_loanContractAddress, 6),
    duration: await provider.getStorageAt(_loanContractAddress, 7),
    balance: await provider.getStorageAt(_loanContractAddress, 8)
  };

  results.borrower = ethers.utils.getAddress(
    ethers.utils.hexStripZeros(results.borrower)
  );
  results.lender = ethers.utils.getAddress(
    ethers.utils.hexStripZeros(results.lender)
  );
  results.tokenContract = ethers.utils.getAddress(
    ethers.utils.hexStripZeros(results.tokenContract)
  );
  results.tokenId = parseInt(results.tokenId, 16);
  results.priority = parseInt(results.priority, 16);
  results.principal = parseInt(results.principal, 16);
  results.fixedInterestRate = parseInt(results.fixedInterestRate, 16);
  results.duration = parseInt(results.duration, 16);
  results.balance = parseInt(results.balance, 16);

  return results;
}
