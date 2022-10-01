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

let BlockTime;
let loanContractFactory, loanContract, loanTreasurey;
let owner, borrower, lender, lenderAlt, treasurer;
let tokenContract, tokenId;

describe("0-0 :: LoanContract initialization tests", function () {
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

  it("0-0-99 :: PASS", async function () {});

  it("0-0-00 :: Verify contract initializer", async function () {
    // Verify LoanProposal getter functions
    let _borrower = (await loanContract.loanParticipants())['borrower'];
    let _tokenContractAddress = (await loanContract.loanParticipants())['tokenContract'];
    let _tokenId = (await loanContract.loanParticipants())['tokenId'];
    let _lender = (await loanContract.loanProperties())['lender']['_value'];
    let _principal = (await loanContract.loanProperties())['principal']['_value'];
    let _fixedInterestRate = (await loanContract.loanProperties())['fixedInterestRate']['_value'];
    let _duration = (await loanContract.loanProperties())['duration']['_value'];
    let _borrowerSigned = (await loanContract.loanProperties())['borrowerSigned']['_value'];
    let _lenderSigned = (await loanContract.loanProperties())['lenderSigned']['_value'];
    _duration = await BlockTime.blocksToDays(_duration);

    expect(_borrower).to.equal(borrower.address, "The borrower address is not correct.");
    expect(_lender).to.equal(ethers.constants.AddressZero, "The lender address is not correct.");
    expect(_tokenContractAddress).to.equal(tokenContract.address, "The token contract address is not correct.");
    expect(_tokenId).to.equal(tokenId, "The token ID is not correct.");
    expect(_principal).to.equal(loanPrincipal, "The principal is not correct.");
    expect(_fixedInterestRate).to.equal(loanFixedInterestRate, "The fixed interest rate is not correct.");
    expect(_duration).to.equal(loanDuration, "The duration is not correct.");
    assert.isTrue(_borrowerSigned , "The borrower signed status is not correct.");
    assert.isFalse(_lenderSigned, "The lender signed status is not correct.");

    // Verify roles
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._ARBITER_ROLE_, loanContract.address),
      "The loan contract is not set with ARBITER role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._BORROWER_ROLE_, borrower.address),
      "The borrower is not set with BORROWER role."
    );
    await assert.eventually.isFalse(
      loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, loanContract.address),
      "The loan contract is set with COLLATERAL_OWNER role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, loanContract.address),
      "The loan contract is set with COLLATERAL_CUSTODIAN role."
    );
    await assert.eventually.isFalse(
      loanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, borrower.address),
      "The borrower is set with COLLATERAL_CUSTODIAN role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
      "The borrower is not set with PARTICIPANT role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
      "The borrower is not set with COLLATERAL_OWNER role."
    );
    await assert.eventually.isTrue(
      loanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, loanContract.address),
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

  it("0-0-01 :: Verify LoanProposal borrower signoffs", async function () {
    // Borrower withdraws LoanContract and LoanContract transfers NFT to borrower
    let _tx = await loanContract.connect(borrower).withdrawNft();
    let [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    let [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    _owner = await tokenContract.ownerOf(tokenId);

    expect(_prevLoanState).to.equal(LOANSTATE.UNSPONSORED, "The previous loan state must be UNSPONSORED.");
    expect(_newLoanState).to.equal(LOANSTATE.NONLEVERAGED, "The new loan state must be NONLEVERAGED.");
    expect(_owner).to.equal(borrower.address, "The token owner should be the borrower.");
    
    // Borrower signs LoanContract and transfers NFT to LoanProposal
    await tokenContract.setApprovalForAll(loanContract.address, true);
    _tx = await loanContract.connect(borrower).sign();
    [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    _owner = await tokenContract.ownerOf(tokenId);

    expect(_prevLoanState).to.equal(LOANSTATE.NONLEVERAGED, "The previous loan state must be NONLEVERAGED.");
    expect(_newLoanState).to.equal(LOANSTATE.UNSPONSORED, "The new loan state must be UNSPONSORED.");
    expect(_owner).to.equal(loanContract.address, "The token owner should be the LoanContract.");
  });

  it("0-0-02 :: Verify LoanProposal setLender function", async function () {
    // Remove collateral leveraged
    await loanContract.withdrawNft();

    // Set lender with lender
    await assert.eventually.isFalse(loanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
    await assert.eventually.isFalse(loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");

    let _tx = await loanContract.connect(lender).setLender({ value: loanPrincipal });
    await assert.eventually.isTrue(loanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");

    let [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    let [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    let [_payee, _weiAmount] = await listenerDeposited(_tx, loanContract);
    expect(_prevLoanState).to.equal(LOANSTATE.NONLEVERAGED, "The previous loan state should be NONLEVERAGED.");
    expect(_newLoanState).to.equal(LOANSTATE.FUNDED, "The new loan state should be FUNDED.");
    expect(_payee).to.equal(lender.address, "The payee should be the lender.");
    expect(_weiAmount.eq(loanPrincipal)).to.equal(true, `The deposited amount should be ${loanPrincipal} WEI.`);

    await assert.eventually.isTrue(loanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");
    await assert.eventually.isTrue(loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender not is set with PARTICIPANT role.");

    // Attempt to steal sponsorship
    await expect(loanContract.connect(lenderAlt).setLender(
      { value: loanPrincipal }
    )).to.be.rejectedWith(/The lender must not currently be signed off./);

    // Remove lender with borrower
    _tx = await loanContract.setLender();
    [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    let _lender = (await loanContract.loanProperties())['lender']['_value'];
    expect(_prevLoanState).to.equal(LOANSTATE.FUNDED, "The previous loan state should be FUNDED.");
    expect(_newLoanState).to.equal(LOANSTATE.UNSPONSORED, "The new loan state should be UNSPONSORED.");
    expect(_lender).to.equal(ethers.constants.AddressZero, "The lender is not set to AddressZero.");
    
    await assert.eventually.isFalse(loanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
    await assert.eventually.isTrue(loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender not is set with PARTICIPANT role.");

    // Remove lender with lender
    await loanContract.connect(lender).setLender();
    _tx = await loanContract.connect(lender).withdrawSponsorship();
    [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    expect(_prevLoanState).to.equal(LOANSTATE.FUNDED, "The previous loan state should be FUNDED.");
    expect(_newLoanState).to.equal(LOANSTATE.UNSPONSORED, "The new loan state should be UNSPONSORED.");

    await assert.eventually.isFalse(loanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
    await assert.eventually.isFalse(loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");

    // Set lender with lender with collateral leveraged
    await tokenContract.approve(loanContract.address, tokenId);
    await loanContract.sign();
    await assert.eventually.isFalse(loanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
    await assert.eventually.isFalse(loanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");

    _tx = await loanContract.connect(lender).setLender({ value: loanPrincipal });
    await assert.eventually.isTrue(loanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");

    [_prevLoanState, _] = await listenerLoanStateChanged(_tx, loanContract);
    [__, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract, false);
    [_payee, _weiAmount] = await listenerDeposited(_tx, loanContract);
    expect(_prevLoanState).to.equal(LOANSTATE.UNSPONSORED, "The previous loan state should be UNSPONSORED.");
    expect(_newLoanState).to.equal(LOANSTATE.ACTIVE_OPEN, "The new loan state should be ACTIVE_OPEN.");
    expect(_payee).to.equal(lender.address, "The payee should be the lender.");
    expect(_weiAmount.eq(loanPrincipal)).to.equal(true, `The deposited amount should be ${loanPrincipal} WEI.`);
  });

  it("0-0-03 :: Verify LoanProposal updateTerms function for single changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    let _loanPrincipal = (await loanContract.loanProperties())['principal']['_value'];
    let _loanFixedInterestRate = (await loanContract.loanProperties())['fixedInterestRate']['_value'];
    let _loanDuration = (await loanContract.loanProperties())['duration']['_value'];
    _loanDuration = await BlockTime.blocksToDays(_loanDuration);
    expect(_loanPrincipal).to.equal(loanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan duration is not set as expected.");

    // Update loan principal
    _tx = await loanContract.updateTerms(['principal'], [_newLoanPrincipal]);
    _loanPrincipal = (await loanContract.loanProperties())['principal']['_value'];
    _loanFixedInterestRate = (await loanContract.loanProperties())['fixedInterestRate']['_value'];
    _loanDuration = (await loanContract.loanProperties())['duration']['_value'];
    _loanDuration = await BlockTime.blocksToDays(_loanDuration);
    expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanDuration).to.equal(loanDuration, "The loan duration is not set as expected.");

    let [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, loanContract);
    expect('principal').to.equal(_params[0], "Emitted event params incorrect.");
    expect(_prevValues[0].toNumber()).to.equal(loanPrincipal, "Emitted event previous principal value incorrect.");
    expect(_newValues[0].toNumber()).to.equal(_newLoanPrincipal, "Emitted event new principal value incorrect.");

    // Update loan fixed interest rate
    _tx = await loanContract.updateTerms(['fixed_interest_rate'], [_newLoanFixedInterestRate]);
    _loanPrincipal = (await loanContract.loanProperties())['principal']['_value'];
    _loanFixedInterestRate = (await loanContract.loanProperties())['fixedInterestRate']['_value'];
    _loanDuration = (await loanContract.loanProperties())['duration']['_value'];
    _loanDuration = await BlockTime.blocksToDays(_loanDuration);
    expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(_newLoanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanDuration).to.equal(loanDuration, "The loan duration is not set as expected.");

    [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, loanContract);
    expect('fixed_interest_rate').to.equal(_params[0], "Emitted event params incorrect.");
    expect(_prevValues[0].toNumber()).to.equal(loanFixedInterestRate, "Emitted event previous fixed interest rate value incorrect.");
    expect(_newValues[0].toNumber()).to.equal(_newLoanFixedInterestRate, "Emitted event new fixed interest rate value incorrect.");

    // Update loan duration
    _tx = await loanContract.updateTerms(['duration'], [_newLoanDuration]);
    _loanPrincipal = (await loanContract.loanProperties())['principal']['_value'];
    _loanFixedInterestRate = (await loanContract.loanProperties())['fixedInterestRate']['_value'];
    _loanDuration = (await loanContract.loanProperties())['duration']['_value'];
    _loanDuration = await BlockTime.blocksToDays(_loanDuration);
    expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
    expect(_loanFixedInterestRate).to.equal(_newLoanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
    expect(_loanDuration).to.equal(_newLoanDuration, "The loan duration is not set as expected.");

    [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, loanContract);
    expect('duration').to.equal(_params[0], "Emitted event params incorrect.");
    await expect(BlockTime.blocksToDays(_prevValues[0].toNumber())).to.eventually.equal(loanDuration, "Emitted event previous duration value incorrect.");
    await expect(BlockTime.blocksToDays(_newValues[0].toNumber())).to.eventually.equal(_newLoanDuration, "Emitted event new duration value incorrect.");
  });

  it("0-0-04 :: Verify LoanProposal updateTerms function for multiple changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    let _loanPrincipal = (await loanContract.loanProperties())['principal']['_value'];
    let _loanFixedInterestRate = (await loanContract.loanProperties())['fixedInterestRate']['_value'];
    let _loanDuration = (await loanContract.loanProperties())['duration']['_value'];
    _loanDuration = await BlockTime.blocksToDays(_loanDuration);

    assert.isTrue(
      _loanPrincipal.eq(loanPrincipal),
      "Loan principal has been modified."
    );

    assert.isTrue(
      _loanFixedInterestRate.eq(loanFixedInterestRate),
      "Loan fixed interest rate has been modified."
    );

    assert.isTrue(
      _loanDuration.eq(loanDuration),
      "Loan duration has been modified."
    );

    // Update all loan parameters
    const _tx = await loanContract.updateTerms(
      ['principal', 'duration', 'fixed_interest_rate'],
      [_newLoanPrincipal, _newLoanDuration, _newLoanFixedInterestRate],
    );

    // Verify loan parameters using getter functions
    _loanPrincipal = (await loanContract.loanProperties())['principal']['_value'];
    _loanFixedInterestRate = (await loanContract.loanProperties())['fixedInterestRate']['_value'];
    _loanDuration = (await loanContract.loanProperties())['duration']['_value'];
    _loanDuration = await BlockTime.blocksToDays(_loanDuration);

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
    await expect(BlockTime.blocksToDays(_prevValues[1])).to.eventually.equal(loanDuration, "Emitted event previous duration value incorrect.");
    await expect(BlockTime.blocksToDays(_newValues[1])).to.eventually.equal(_newLoanDuration, "Emitted event new duration value incorrect.");
  });

  it("0-0-05 :: Verify loan activation on borrower sign", async function () {
    // Unsign borrower
    await loanContract.withdrawNft();

    // Sign lender
    await loanContract.connect(lender).setLender({ value: loanPrincipal });

    // Sign borrower
    await tokenContract.approve(loanContract.address, tokenId);
    let _tx = await loanContract.sign();
    let [_loanContractAddress, _borrowerAddress, _lenderAddress, _tokenContractAddress, _tokenId, _loanState] = await listenerLoanActivated(_tx, loanContract);
    expect(_loanContractAddress).to.equal(loanContract.address, "The loan contract address is not expected.");
    expect(_borrowerAddress).to.equal(borrower.address, "The borrower address is not expected.");
    expect(_lenderAddress).to.equal(lender.address, "The lender address is not expected.");
    expect(_tokenContractAddress).to.equal(tokenContract.address, "The token contract is not expected.");
    expect(_tokenId).to.equal(tokenId, "The token ID is not expected.");
    expect(_loanState).to.equal(LOANSTATE.ACTIVE_OPEN, "The loan state is not expected.");
  });

  it("0-0-06 :: Verify loan activation on lender sign", async function () {
    // Sign lender
    let _tx = await loanContract.connect(lender).setLender({ value: loanPrincipal });
    let [_loanContractAddress, _borrowerAddress, _lenderAddress, _tokenContractAddress, _tokenId, _loanState] = await listenerLoanActivated(_tx, loanContract);
    expect(_loanContractAddress).to.equal(loanContract.address, "The loan contract address is not expected.");
    expect(_borrowerAddress).to.equal(borrower.address, "The borrower address is not expected.");
    expect(_lenderAddress).to.equal(lender.address, "The lender address is not expected.");
    expect(_tokenContractAddress).to.equal(tokenContract.address, "The token contract is not expected.");
    expect(_tokenId).to.equal(tokenId, "The token ID is not expected.");
    expect(_loanState).to.equal(LOANSTATE.ACTIVE_OPEN, "The loan state is not expected.");
  });

  it("0-0-07 :: Need to test withdrawFunds()", async function () {});
  it("0-0-08 :: Need to test close()", async function () {});
});
