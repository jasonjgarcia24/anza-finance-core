const { assert, expect } = require("chai");
const { ethers, network } = require("hardhat");
const { TRANSFERIBLES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const {
  listenerLoanLenderChanged,
  listenerLoanParamChanged,
  listenerLoanStateChanged
} = require("../utils/listenersILoanAgreement");
const { listenerLoanProposalCreated } = require("../utils/listenersALoanManager");
const { listenerLoanSignoffChanged } = require("../utils/listenersALoanAffirm");

const loanState = {
  UNDEFINED: 0,
  UNSPONSORED: 1,
  SPONSORED: 2,
  FUNDED: 3,
  ACTIVE_GRACE_COMMITTED: 4,
  ACTIVE_GRACE_OPEN: 5,
  ACTIVE_COMMITTED: 6,
  ACTIVE_OPEN: 7,
  PAID: 8,
  DEFAULT: 9,
  AUCTION: 10,
  CLOSED: 11
};

let loanProposal;
let borrower, lender, approver, operator;
let tokenContract, tokenId;
let loanPrincipal = 1;
let loanFixedInterestRate = 2;
let loanDuration = 3;

describe("0-0 :: LoanProposal tests", function () {
  /* NFT and LoanProposal setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [borrower, lender, approver, operator, ..._] = await ethers.getSigners();

    // Establish NFT identifiers
    tokenContract = new ethers.Contract(
      TRANSFERIBLES[0].nft, TRANSFERIBLES[0].abi, borrower
    );
    tokenId = TRANSFERIBLES[0].tokenId;

    // Create LoanProposal for NFT
    const LoanProposalFactory = await ethers.getContractFactory("LoanProposal");
    loanProposal = await LoanProposalFactory.deploy();
    await loanProposal.deployed();

    await loanProposal.connect(borrower).createLoanProposal(
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );

    // Set operator
    await tokenContract.setApprovalForAll(operator.address, true);
    await tokenContract.setApprovalForAll(loanProposal.address, true);

    // Set NFT approver
    await tokenContract.approve(approver.address, tokenId);
  });

  it("0-0-99 :: PASS", async function () { });

  it("0-0-00 :: Test LoanProposal getter functions", async function () {
    // Check loan ID
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);
    expect(_loanId).to.equal(0, "Loan ID should be 0.");

    // Check loan principal
    const _loanTerms = await loanProposal.getLoanTerms(
      tokenContract.address, tokenId, _loanId
    );
    assert.isTrue(
      _loanTerms[0].eq(loanPrincipal) &&
      _loanTerms[1].eq(loanFixedInterestRate) &&
      _loanTerms[2].eq(loanDuration),
      "Loan terms has been modified."
    );

    // Check loan state
    const _loanState = await loanProposal.getLoanState(
      tokenContract.address, tokenId, _loanId
    );
    expect(_loanState).to.equal(1, "Loan state should be 1.");

    // Check loan lender
    const _lenderAddress = await loanProposal.getLender(
      tokenContract.address, tokenId, _loanId
    );
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");
  });

  it("0-0-01 :: Test LoanProposal setLender function", async function () {
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);
    let _, _prevLoanState, _newLoanState;

    // Check initial lender address
    let _lenderAddress = await loanProposal.getLender(
      tokenContract.address, tokenId, _loanId
    );
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // Check added lender with lender
    [_prevLoanState, _newLoanState, _lenderAddress] = await updateLender(lender, _loanId, lender.address);
    expect(_prevLoanState).to.equal(loanState.UNSPONSORED, `Previous loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_newLoanState).to.equal(loanState.FUNDED, `Loan proposal state should be ${loanState.FUNDED}.`);
    expect(_lenderAddress).to.equal(lender.address, `Loan lender should be ${lender.address}.`);

    // Check removed lender with borrower
    [_, _newLoanState, _lenderAddress] = await updateLender(borrower, _loanId);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // Check removed lender with approver
    await updateLender(lender, _loanId, lender.address);
    [_, _newLoanState, _lenderAddress] = await updateLender(approver, _loanId);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // Check removed lender with operator
    await updateLender(lender, _loanId, lender.address);
    [_, _newLoanState, _lenderAddress] = await updateLender(operator, _loanId);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");
    
    // Check removed lender with lender
    await updateLender(lender, _loanId, lender.address);
    [_, _newLoanState, _lenderAddress] = await updateLender(operator, _loanId);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");
  });

  it("0-0-02 :: Test LoanProposal setLoanParm function for single changes", async function () {
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    const _prevLoanTerms = await loanProposal.getLoanTerms(
      tokenContract.address, tokenId, _loanId
    );

    assert.isTrue(
      _prevLoanTerms[0].eq(loanPrincipal) &&
      _prevLoanTerms[1].eq(loanFixedInterestRate) &&
      _prevLoanTerms[2].eq(loanDuration),
      "Loan terms have been modified."
    );

    // Check loan principal
    let _newLoanTerms = await updateLoanParams(
      _loanId, ['principal'], [_newLoanPrincipal], [_prevLoanTerms[0]]
    );

    assert.isTrue(
      _newLoanTerms[0].eq(_newLoanPrincipal) &&
      _newLoanTerms[1].eq(loanFixedInterestRate) &&
      _newLoanTerms[2].eq(loanDuration),
      "Loan principal change is not correct."
    );

    // Check loan fixed interest rate
    _newLoanTerms = await updateLoanParams(
      _loanId, ['fixed_interest_rate'], [_newLoanFixedInterestRate], [_prevLoanTerms[1]]
    );

    assert.isTrue(
      _newLoanTerms[0].eq(_newLoanPrincipal) &&
      _newLoanTerms[1].eq(_newLoanFixedInterestRate) &&
      _newLoanTerms[2].eq(loanDuration),
      "Loan fixed interest rate change is not correct."
    );

    // Check loan duration
    _newLoanTerms = await updateLoanParams(
      _loanId, ['duration'], [_newLoanDuration], [_prevLoanTerms[2]]
    );

    assert.isTrue(
      _newLoanTerms[0].eq(_newLoanPrincipal) &&
      _newLoanTerms[1].eq(_newLoanFixedInterestRate) &&
      _newLoanTerms[2].eq(_newLoanDuration),
      "Loan duration change is not correct."
    );
  });

  it("0-0-03 :: Test LoanProposal setLoanParm function for multiple changes", async function () {
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    const _prevLoanTerms = await loanProposal.getLoanTerms(
      tokenContract.address, tokenId, _loanId
    );

    assert.isTrue(
      _prevLoanTerms[0].eq(loanPrincipal) &&
      _prevLoanTerms[1].eq(loanFixedInterestRate) &&
      _prevLoanTerms[2].eq(loanDuration),
      "Loan terms have been modified."
    );

    // Check loan all loan parameters
    let _newLoanTerms = await updateLoanParams(
      _loanId,
      ['principal', 'fixed_interest_rate', 'duration'],
      [_newLoanPrincipal, _newLoanFixedInterestRate, _newLoanDuration],
      _prevLoanTerms
    );

    assert.isTrue(
      _newLoanTerms[0].eq(_newLoanPrincipal),
      "Loan principal change is not correct."
    );

    assert.isTrue(
      _newLoanTerms[1].eq(_newLoanFixedInterestRate),
      "Loan fixed interest rate change is not correct."
    );

    assert.isTrue(
      _newLoanTerms[2].eq(_newLoanDuration),
      "Loan duration change is not correct."
    );
  });

  it("0-0-04 :: Test LoanProposal borrower signoffs.", async function () {
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);

    // Borrower signs LoanProposal and transfers NFT to LoanProposal
    let _tx = await loanProposal.connect(borrower).sign(tokenContract.address, tokenId, _loanId);
    let [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);

    expect(_signer).to.equal(borrower.address, "Borrower and signer are not the same.");
    assert.isTrue(_action.eq(1), "Unsign action is not expected.");
    assert.isTrue(_borrowerSignStatus, "Borrower sign status is not true.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    let _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(loanProposal.address, "The LoanProposal contract is not the token owner.");

    // Borrower unsigns LoanProposal and LoanProposal transfers NFT to borrower
    _tx = await loanProposal.connect(borrower).unsign(tokenContract.address, tokenId, _loanId);
    [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);

    expect(_signer).to.equal(borrower.address, "Borrower and signer are not the same.");
    assert.isFalse(_action.eq(1), "Sign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(borrower.address, "The borrower is not the token owner.");
  });

  it("0-0-05 :: Test LoanProposal lender signoffs.", async function () {
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);

    // Lender signs LoanProposal via setLender and transfers funds to LoanProposal
    let _tx = await loanProposal.connect(lender).setLender(
      lender.address, tokenContract.address, tokenId, _loanId, { value: loanPrincipal }
    );
    [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);

    expect(_signer).to.equal(lender.address, "Lender and signer are not the same.");
    assert.isTrue(_action.eq(1), "Unsign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isTrue(_lenderSignStatus, "Lender sign status is not true.");

    // Lender unsigns LoanProposal and LoanProposal transfers funds to lender
    _tx = await loanProposal.connect(lender).unsign(tokenContract.address, tokenId, _loanId);
    [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);


    expect(_signer).to.equal(lender.address, "Lender and signer are not the same.");
    assert.isFalse(_action.eq(1), "Sign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    let _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(_owner, borrower.address, "The borrower is not the token owner.");

    // Lender signs LoanProposal and transfers funds to LoanProposal
    _tx = await loanProposal.connect(borrower).sign(tokenContract.address, tokenId, _loanId);
    [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);


    expect(_signer).to.equal(borrower.address, "Borrower and signer are not the same.");
    assert.isTrue(_action.eq(1), "Unsign action is not expected.");
    assert.isTrue(_borrowerSignStatus, "Borrower sign status is not true.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(loanProposal.address, "The LoanProposal contract is not the token owner.");
  });
});

const updateLender = async (_sender, _loanId, _setAddress=ethers.constants.AddressZero) => {
  const _tx = await loanProposal.connect(_sender).setLender(
    _setAddress, tokenContract.address, tokenId, _loanId, { value: loanPrincipal }
  );

  const [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, loanProposal);
  const [_, _newLender] = await listenerLoanLenderChanged(_tx, loanProposal);

  return [_prevLoanState, _newLoanState, _newLender];
}

const updateLoanParams = async (_loanId, _params, _newValues, _prevValues) => {
  const _tx = await loanProposal.setLoanParam(
    tokenContract.address,
    tokenId,
    _loanId,
    _params,
    _newValues
  );

  const _newLoanTerms = await loanProposal.getLoanTerms(
    tokenContract.address, tokenId, _loanId
  );

  // Check LoanParamChanged event triggered
  const _inputParamHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(_params.at(-1)));
  let [_outputParamHash, _outputPrevValue, _outputNewValue] = await listenerLoanParamChanged(_tx, loanProposal);

  assert.equal(_outputParamHash, _inputParamHash, "param emitted is not correct.");
  assert.equal(_outputPrevValue.toNumber(), _prevValues.at(-1).toNumber(), "prevValue emitted is not correct.");
  assert.equal(_outputNewValue.toNumber(), _newValues.at(-1), "newValue emitted is not correct.");

  return _newLoanTerms;
}
