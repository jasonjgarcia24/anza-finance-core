const { assert, expect } = require("chai");
const { ethers, network } = require("hardhat");
const { TRANSFERIBLES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const {
  listenerLoanLenderChanged,
  listenerLoanParamChanged,
  listenerLoanStateChanged
} = require("../utils/listenersIProposal");
const { listenerLoanProposalCreated } = require("../utils/listenersAProposalManager");
const { listenerLoanSignoffChanged } = require("../utils/listenersAProposalAffirm");
const { listenerLoanContractDeployed } = require("../utils/listenersAProposalContractInteractions");

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
  CLOSED: 12
};

let provider;
let loanProposal, loanId, loanContract;
let borrower, lender, lenderAlt, approver, operator;
let tokenContract, tokenId;
let loanPrincipal = 10;
let loanFixedInterestRate = 2;
let loanDuration = 3;

describe("0-0 :: LoanProposal tests", function () {
  /* NFT and LoanProposal setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [borrower, lender, lenderAlt, approver, operator, ..._] = await ethers.getSigners();

    // Establish NFT identifiers
    tokenContract = new ethers.Contract(
      TRANSFERIBLES[0].nft, TRANSFERIBLES[0].abi, borrower
    );
    tokenId = TRANSFERIBLES[0].tokenId;

    // Create LoanProposal for NFT
    const LoanProposalFactory = await ethers.getContractFactory("LoanProposal");
    loanProposal = await LoanProposalFactory.deploy();
    await loanProposal.deployed();
    await tokenContract.setApprovalForAll(loanProposal.address, true);

    await loanProposal.connect(borrower).createLoanProposal(
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
    loanId = await loanProposal.getLoanCount(tokenContract.address, tokenId);
    await loanProposal.withdraw(tokenContract.address, tokenId, loanId);

    // Set operator
    await tokenContract.setApprovalForAll(operator.address, true);

    // Set NFT approver
    await tokenContract.approve(approver.address, tokenId);
  });

  it("0-0-99 :: PASS", async function () { });

  it("0-0-00 :: Test LoanProposal getter functions", async function () {
    // Check loan ID
    expect(loanId).to.equal(0, "Loan ID should be 0.");

    // Check loan principal
    const _loanTerms = await loanProposal.getLoanTerms(
      tokenContract.address, tokenId, loanId
    );
    assert.isTrue(
      _loanTerms[0].eq(loanPrincipal) &&
      _loanTerms[1].eq(loanFixedInterestRate) &&
      _loanTerms[2].eq(loanDuration),
      "Loan terms has been modified."
    );

    // Check loan state
    const _loanState = await loanProposal.getLoanState(
      tokenContract.address, tokenId, loanId
    );
    expect(_loanState).to.equal(1, "Loan state should be 1.");

    // Check loan lender
    const _lenderAddress = await loanProposal.getLender(
      tokenContract.address, tokenId, loanId
    );
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");
  });

  it("0-0-01 :: Test LoanProposal setLender function", async function () {
    let _, _currentLoanState, _prevLoanState, _newLoanState, _newestLoanState;

    // Check initial lender address
    let _lenderAddress = await loanProposal.getLender(
      tokenContract.address, tokenId, loanId
    );
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // Check added lender with lender
    [_prevLoanState, _newLoanState, _lenderAddress] = await updateLender(lender, loanId);
    _newestLoanState = await loanProposal.getState(tokenContract.address, tokenId, loanId);
    expect(_prevLoanState).to.equal(loanState.NONLEVERAGED, `Previous loan proposal state should be ${loanState.NONLEVERAGED}.`);
    expect(_newLoanState).to.equal(loanState.SPONSORED, `Loan proposal state should be ${loanState.SPONSORED}.`);
    expect(_newestLoanState).to.equal(loanState.FUNDED, `Loan proposal state should be ${loanState.FUNDED}.`);
    expect(_lenderAddress).to.equal(lender.address, `Loan lender should be ${lender.address}.`);

    // Check removed lender with borrower
    [_prevLoanState, _newLoanState, _lenderAddress] = await updateLender(borrower, loanId);
    expect(_prevLoanState).to.equal(loanState.SPONSORED, `Previous loan proposal state should be ${loanState.SPONSORED}.`);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // Check removed lender with approver
    await updateLender(lender, loanId);
    [_, _newLoanState, _lenderAddress] = await updateLender(approver, loanId);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // Check removed lender with operator
    await updateLender(lender, loanId);
    [_, _newLoanState, _lenderAddress] = await updateLender(operator, loanId);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");
    
    // Check new lender with lenderAlt
    await updateLender(lender, loanId);
    await loanProposal.connect(lender).withdraw(tokenContract.address, tokenId, loanId);
    [_, _newLoanState, _lenderAddress] = await updateLender(lenderAlt, loanId);
    _newestLoanState = await loanProposal.getState(tokenContract.address, tokenId, loanId);
    expect(_newLoanState).to.equal(loanState.SPONSORED, `Loan proposal state should be ${loanState.SPONSORED}.`);
    expect(_newestLoanState).to.equal(loanState.FUNDED, `Loan proposal state should be ${loanState.FUNDED}.`);
    expect(_lenderAddress).to.equal(lenderAlt.address, "Loan lender should be the alternate lender's address.");
  });

  it("0-0-02 :: Test LoanProposal setLoanParm function for single changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    const _prevLoanTerms = await loanProposal.getLoanTerms(
      tokenContract.address, tokenId, loanId
    );

    assert.isTrue(
      _prevLoanTerms[0].eq(loanPrincipal) &&
      _prevLoanTerms[1].eq(loanFixedInterestRate) &&
      _prevLoanTerms[2].eq(loanDuration),
      "Loan terms have been modified."
    );

    // Check loan principal
    let _newLoanTerms = await updateLoanParams(
      loanId, ['principal'], [_newLoanPrincipal], [_prevLoanTerms[0]]
    );

    assert.isTrue(
      _newLoanTerms[0].eq(_newLoanPrincipal) &&
      _newLoanTerms[1].eq(loanFixedInterestRate) &&
      _newLoanTerms[2].eq(loanDuration),
      "Loan principal change is not correct."
    );

    // Check loan fixed interest rate
    _newLoanTerms = await updateLoanParams(
      loanId, ['fixed_interest_rate'], [_newLoanFixedInterestRate], [_prevLoanTerms[1]]
    );

    assert.isTrue(
      _newLoanTerms[0].eq(_newLoanPrincipal) &&
      _newLoanTerms[1].eq(_newLoanFixedInterestRate) &&
      _newLoanTerms[2].eq(loanDuration),
      "Loan fixed interest rate change is not correct."
    );

    // Check loan duration
    _newLoanTerms = await updateLoanParams(
      loanId, ['duration'], [_newLoanDuration], [_prevLoanTerms[2]]
    );

    assert.isTrue(
      _newLoanTerms[0].eq(_newLoanPrincipal) &&
      _newLoanTerms[1].eq(_newLoanFixedInterestRate) &&
      _newLoanTerms[2].eq(_newLoanDuration),
      "Loan duration change is not correct."
    );
  });

  it("0-0-03 :: Test LoanProposal setLoanParm function for multiple changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    // Collect and check original loan terms
    const _prevLoanTerms = await loanProposal.getLoanTerms(
      tokenContract.address, tokenId, loanId
    );

    assert.isTrue(
      _prevLoanTerms[0].eq(loanPrincipal) &&
      _prevLoanTerms[1].eq(loanFixedInterestRate) &&
      _prevLoanTerms[2].eq(loanDuration),
      "Loan terms have been modified."
    );

    // Check loan all loan parameters
    let _newLoanTerms = await updateLoanParams(
      loanId,
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
    // Borrower signs LoanProposal and transfers NFT to LoanProposal
    let _tx = await loanProposal.connect(borrower).sign(tokenContract.address, tokenId, loanId);
    let [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);

    expect(_signer).to.equal(borrower.address, "Borrower and signer are not the same.");
    assert.isTrue(_action.eq(1), "withdraw action is not expected.");
    assert.isTrue(_borrowerSignStatus, "Borrower sign status is not true.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    let _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(loanProposal.address, "The LoanProposal contract is not the token owner.");

    // Borrower withdraws LoanProposal and LoanProposal transfers NFT to borrower
    _tx = await loanProposal.connect(borrower).withdraw(tokenContract.address, tokenId, loanId);
    [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);

    expect(_signer).to.equal(borrower.address, "Borrower and signer are not the same.");
    assert.isFalse(_action.eq(1), "Sign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");

    _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(borrower.address, "The borrower is not the token owner.");
  });

  it("0-0-05 :: Test LoanProposal lender signoffs.", async function () {
    let _, _prevLoanState, _newLoanState;

    // Lender signs LoanProposal via setLender and transfers funds to LoanProposal
    let _tx = await loanProposal.connect(lender).setLender(
      tokenContract.address, tokenId, loanId, { value: loanPrincipal }
    );
    [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);

    expect(_signer).to.equal(lender.address, "Lender and signer are not the same.");
    assert.isTrue(_action.eq(1), "withdraw action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isTrue(_lenderSignStatus, "Lender sign status is not true.");

    // Lender withdraws from LoanProposal
    _tx = await loanProposal.connect(lender).withdraw(tokenContract.address, tokenId, loanId);
    [_signer, _action, _borrowerSignStatus, _lenderSignStatus] = await listenerLoanSignoffChanged(_tx, loanProposal);
    [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, loanProposal);

    expect(_signer).to.equal(lender.address, "Lender and signer are not the same.");
    assert.isFalse(_action.eq(1), "Sign action is not expected.");
    assert.isFalse(_borrowerSignStatus, "Borrower sign status is not false.");
    assert.isFalse(_lenderSignStatus, "Lender sign status is not false.");
    
    expect(_prevLoanState).to.equal(loanState.SPONSORED, `Previous loan proposal state should be ${loanState.SPONSORED}.`);
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);

    // Lender cannot signs LoanProposal with sign function
    assert.eventually.throws(
      loanProposal.connect(lender).sign(
        tokenContract.address, tokenId, loanId, { value: loanPrincipal },
        /Only the borrower can sign. If lending, use setLender()/
      ),
    );
  });

  it("0-0-06 :: Test LoanProposal deploy LoanContract.", async function () {
    let loanContractAddress;
    let _tx = await loanProposal.connect(lender).setLender(tokenContract.address, tokenId, loanId, { value: loanPrincipal });
    _tx = await loanProposal.connect(borrower).sign(tokenContract.address, tokenId, loanId);
    [loanContractAddress, borrower, lender, tokenContract, tokenId] = await listenerLoanContractDeployed(_tx, loanProposal);

    let loanContract = await ethers.getContractAt("LoanContract", loanContractAddress);
    let _var = await provider.getStorageAt(loanContract.address, 0);

    console.log(_var);
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
