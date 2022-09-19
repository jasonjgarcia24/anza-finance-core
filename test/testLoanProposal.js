const { assert, expect } = require("chai");
const { ethers, network } = require("hardhat");
const { TRANSFERIBLES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");

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
    assert.equal(0, _loanId, "Loan ID should be 0.");

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
    assert.equal(1, _loanState, "Loan state should be 1.");

    // Check loan lender
    const _lenderAddress = await loanProposal.getLender(
      tokenContract.address, tokenId, _loanId
    );
    assert.equal(ethers.constants.AddressZero, _lenderAddress, "Loan lender should be address zero.");
  });

  it("0-0-01 :: Test LoanProposal setLender function", async function () {
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);
    let _lenderAddress = await loanProposal.getLender(
      tokenContract.address, tokenId, _loanId
    );
    assert.equal(ethers.constants.AddressZero, _lenderAddress, "Loan lender should be address zero.");

    // Check changed lender with lender
    _lenderAddress = await updateLender(lender, _loanId);
    assert.equal(lender.address, _lenderAddress, `Loan lender should be ${lender.address}.`);

    // Check removed lender with borrower
    _lenderAddress = await updateLender(borrower, _loanId);
    assert.equal(ethers.constants.AddressZero, _lenderAddress, "Loan lender should be address zero.");

    // Check removed lender with approver
    await updateLender(lender, _loanId);
    _lenderAddress = await updateLender(approver, _loanId);
    assert.equal(ethers.constants.AddressZero, _lenderAddress, "Loan lender should be address zero.");

    // Check removed lender with operator
    await updateLender(lender, _loanId);
    _lenderAddress = await updateLender(operator, _loanId);
    assert.equal(ethers.constants.AddressZero, _lenderAddress, "Loan lender should be address zero.");
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
    const _topic = loanProposal.interface.getEventTopic('LoanSignoffChanged');

    // Borrower signs LoanProposal and transfers NFT to LoanProposal
    let _tx = await loanProposal.connect(borrower).sign(tokenContract.address, tokenId, _loanId);
    let _receipt = await _tx.wait();
    let _log = _receipt.logs.find(x => x.topics.indexOf(_topic) >= 0); 
    let _event = loanProposal.interface.parseLog(_log);
    
    let _signer = _event.args['signer'];
    let _action = _event.args['action'];
    let _borrowerSignStatus = _event.args['borrowerSignStatus'];
    let _lenderSignStatus = _event.args['lenderSignStatus'];

    assert.equal(borrower.address, _signer, "Borrower and signer are not the same.");
    assert.isTrue(_action.eq(1), "Unsign action is not expected.");
    assert.isTrue(_borrowerSignStatus, "Borrower sign status is not true.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    let _owner = await tokenContract.ownerOf(tokenId);
    assert.equal(_owner, loanProposal.address, "The LoanProposal contract is not the token owner.");

    // Borrower unsigns LoanProposal and LoanProposal transfers NFT to borrower
    _tx = await loanProposal.connect(borrower).unsign(tokenContract.address, tokenId, _loanId);
    _receipt = await _tx.wait();
    _log = _receipt.logs.find(x => x.topics.indexOf(_topic) >= 0);
    _event = loanProposal.interface.parseLog(_log);
    
    _signer = _event.args['signer'];
    _action = _event.args['action'];
    _borrowerSignStatus = _event.args['borrowerSignStatus'];
    _lenderSignStatus = _event.args['lenderSignStatus'];

    assert.equal(borrower.address, _signer, "Borrower and signer are not the same.");
    assert.isFalse(_action.eq(1), "Sign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    _owner = await tokenContract.ownerOf(tokenId);
    assert.equal(_owner, borrower.address, "The borrower is not the token owner.");
  });

  it("0-0-05 :: Test LoanProposal lender signoffs.", async function () {
    const _loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);
    const _topic = loanProposal.interface.getEventTopic('LoanSignoffChanged');

    // Lender signs LoanProposal via setLender and transfers funds to LoanProposal
    let _tx = await loanProposal.connect(lender).setLender(
      tokenContract.address, tokenId, _loanId, { value: loanPrincipal }
    );
    let _receipt = await _tx.wait();
    let _log = _receipt.logs.find(x => x.topics.indexOf(_topic) >= 0); 
    let _event = loanProposal.interface.parseLog(_log);
    
    let _signer = _event.args['signer'];
    let _action = _event.args['action'];
    let _borrowerSignStatus = _event.args['borrowerSignStatus'];
    let _lenderSignStatus = _event.args['lenderSignStatus'];

    assert.equal(lender.address, _signer, "Lender and signer are not the same.");
    assert.isTrue(_action.eq(1), "Unsign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isTrue(_lenderSignStatus, "Lender sign status is not true.");

    // Lender unsigns LoanProposal and LoanProposal transfers funds to lender
    _tx = await loanProposal.connect(lender).unsign(tokenContract.address, tokenId, _loanId);
    _receipt = await _tx.wait();
    _log = _receipt.logs.find(x => x.topics.indexOf(_topic) >= 0);
    _event = loanProposal.interface.parseLog(_log);
    
    _signer = _event.args['signer'];
    _action = _event.args['action'];
    _borrowerSignStatus = _event.args['borrowerSignStatus'];
    _lenderSignStatus = _event.args['lenderSignStatus'];

    assert.equal(lender.address, _signer, "Lender and signer are not the same.");
    assert.isFalse(_action.eq(1), "Sign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    // _owner = await tokenContract.ownerOf(tokenId);
    // assert.equal(_owner, borrower.address, "The borrower is not the token owner.");

    // // Lender signs LoanProposal and transfers funds to LoanProposal
    // _tx = await loanProposal.connect(borrower).sign(tokenContract.address, tokenId, _loanId);
    // _receipt = await _tx.wait();
    // _log = _receipt.logs.find(x => x.topics.indexOf(_topic) >= 0); 
    // _event = loanProposal.interface.parseLog(_log);
    
    // _signer = _event.args['signer'];
    // _action = _event.args['action'];
    // _borrowerSignStatus = _event.args['borrowerSignStatus'];
    // _lenderSignStatus = _event.args['lenderSignStatus'];

    // assert.equal(borrower.address, _signer, "Borrower and signer are not the same.");
    // assert.isTrue(_action.eq(1), "Unsign action is not expected.");
    // assert.isTrue(_borrowerSignStatus, "Borrower sign status is not true.");
    // assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    // let _owner = await tokenContract.ownerOf(tokenId);
    // assert.equal(_owner, loanProposal.address, "The LoanProposal contract is not the token owner.");
  });
});

const updateLender = async (sender, loanId) => {
  const _topic = loanProposal.interface.getEventTopic('LoanLenderChanged');
  const _tx = await loanProposal.connect(sender).setLender(
    tokenContract.address, tokenId, loanId, { value : loanPrincipal }
  );
  const _receipt = await _tx.wait();
  const _log = _receipt.logs.find(x => x.topics.indexOf(_topic) >= 0);
  const _event = loanProposal.interface.parseLog(_log);

  return _event.args['newLender'];
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
  const _topic = loanProposal.interface.getEventTopic('LoanParamChanged');
  const _receipt = await _tx.wait();
  const _log = _receipt.logs.find(x => x.topics.indexOf(_topic) >= 0);
  const _event = loanProposal.interface.parseLog(_log);

  const _inputParamHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(_params.at(-1)));
  const _outputParamHash = _event.args['param'];
  const _outputPrevValue = _event.args['prevValue'];
  const _outputNewValue = _event.args['newValue'];

  assert.equal(_outputParamHash, _inputParamHash, "param emitted is not correct.");
  assert.equal(_outputPrevValue.toNumber(), _prevValues.at(-1).toNumber(), "prevValue emitted is not correct.");
  assert.equal(_outputNewValue.toNumber(), _newValues.at(-1), "newValue emitted is not correct.");

  return _newLoanTerms;
}
