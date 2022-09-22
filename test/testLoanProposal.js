const { assert, expect } = require("chai");
const { ethers, network, artifacts } = require("hardhat");
const { TRANSFERIBLES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const {
  listenerLoanContractCreated,
  listenerLoanLenderChanged,
  listenerLoanParamChanged
} = require("../utils/listenersIProposal");
const { listenerLoanSignoffChanged } = require("../utils/listenersAProposalAffirm");
const { listenerLoanContractDeployed } = require("../utils/listenersAProposalContractInteractions");
const { listenerLoanStateChanged } = require("../utils/listenersAContractGlobals");

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

const loanExpectedPriority = 1;
const loanPrincipal = ethers.utils.parseEther('0.0001');
const loanFixedInterestRate = 23;
const loanDuration = 3;

describe("0-0 :: LoanProposal tests", function () {
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
    const LoanProposalFactory = await ethers.getContractFactory("LoanProposal");
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
    let _isBorrower = await loanContract.connect(borrower).isBorrower();
    assert.isTrue(_isBorrower, "The borrower is not set.");

    let _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(loanContract.address, "The LoanContract must be the token owner.");
  });

  it("0-0-99 :: PASS", async function () {});

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

  it("0-0-01 :: Test LoanProposal borrower signoffs", async function () {
    let _owner = await tokenContract.ownerOf(tokenId);
    expect(_owner).to.equal(loanContract.address, "The LoanProposal contract is not the token owner.");

    // Borrower withdraws LoanProposal and LoanProposal transfers NFT to borrower
    let _tx = await loanContract.connect(borrower).withdrawNft();
    let [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract);
    _owner = await tokenContract.ownerOf(tokenId);

    expect(_prevLoanState).to.equal(loanState.UNSPONSORED, "The previous loan must be UNSPONSORED.");
    expect(_newLoanState).to.equal(loanState.NONLEVERAGED, "The new loan must be NONLEVERAGED.");
    expect(_owner).to.equal(borrower.address, "The token owner should be the borrower.");
    
    // Borrower signs LoanProposal and transfers NFT to LoanProposal
    await tokenContract.setApprovalForAll(loanContract.address, true);
    _tx = await loanContract.connect(borrower).sign();
    [_prevLoanState, _newLoanState] = await listenerLoanStateChanged(_tx, loanContract);
    _owner = await tokenContract.ownerOf(tokenId);

    expect(_prevLoanState).to.equal(loanState.NONLEVERAGED, "The previous loan must be NONLEVERAGED.");
    expect(_newLoanState).to.equal(loanState.UNSPONSORED, "The new loan must be UNSPONSORED.");
    expect(_owner).to.equal(loanContract.address, "The token owner should be the LoanContract.");
  });

  it("0-0-02 :: Test LoanProposal setLender function", async function () {
    // Check initial lender address
    let _isLender = await loanContract.connect(lender).isLender();
    assert.isFalse(_isLender, "Loan lender should not be set.");

    await loanContract.connect(lender).setLender({ value: loanPrincipal });
    _isLender = await loanContract.connect(lender).isLender();
    assert.isTrue(_isLender, "Loan lender should be set.");

    // // Check added lender with lender
    // [_prevLoanState, _newLoanState, _lenderAddress] = await updateLender(lender, loanId);
    // _newestLoanState = await loanProposal.getState(tokenContract.address, tokenId, loanId);
    // expect(_prevLoanState).to.equal(loanState.NONLEVERAGED, `Previous loan proposal state should be ${loanState.NONLEVERAGED}.`);
    // expect(_newLoanState).to.equal(loanState.SPONSORED, `Loan proposal state should be ${loanState.SPONSORED}.`);
    // expect(_newestLoanState).to.equal(loanState.FUNDED, `Loan proposal state should be ${loanState.FUNDED}.`);
    // expect(_lenderAddress).to.equal(lender.address, `Loan lender should be ${lender.address}.`);

    // // Check removed lender with borrower
    // [_prevLoanState, _newLoanState, _lenderAddress] = await updateLender(borrower, loanId);
    // expect(_prevLoanState).to.equal(loanState.SPONSORED, `Previous loan proposal state should be ${loanState.SPONSORED}.`);
    // expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    // expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // // Check removed lender with approver
    // await updateLender(lender, loanId);
    // [_, _newLoanState, _lenderAddress] = await updateLender(approver, loanId);
    // expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    // expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");

    // // Check removed lender with operator
    // await updateLender(lender, loanId);
    // [_, _newLoanState, _lenderAddress] = await updateLender(operator, loanId);
    // expect(_newLoanState).to.equal(loanState.UNSPONSORED, `Loan proposal state should be ${loanState.UNSPONSORED}.`);
    // expect(_lenderAddress).to.equal(ethers.constants.AddressZero, "Loan lender should be address zero.");
    
    // // Check new lender with lenderAlt
    // await updateLender(lender, loanId);
    // await loanProposal.connect(lender).withdraw(tokenContract.address, tokenId, loanId);
    // [_, _newLoanState, _lenderAddress] = await updateLender(lenderAlt, loanId);
    // _newestLoanState = await loanProposal.getState(tokenContract.address, tokenId, loanId);
    // expect(_newLoanState).to.equal(loanState.SPONSORED, `Loan proposal state should be ${loanState.SPONSORED}.`);
    // expect(_newestLoanState).to.equal(loanState.FUNDED, `Loan proposal state should be ${loanState.FUNDED}.`);
    // expect(_lenderAddress).to.equal(lenderAlt.address, "Loan lender should be the alternate lender's address.");
  });

  it("0-0-03 :: Test LoanProposal setLoanParm function for single changes", async function () {
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

  it("0-0-04 :: Test LoanProposal setLoanParm function for multiple changes", async function () {
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

  it("0-0-05 :: Test LoanProposal lender signoffs", async function () {
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

  it("0-0-06 :: Test LoanProposal deploy LoanContract", async function () {
    let _borrowerBalance = await provider.getBalance(borrower.address);
    let _proposalBalance = await provider.getBalance(loanProposal.address);
    console.log(`Initial borrower balance: ${_borrowerBalance}`);
    console.log(`Initial proposal balance: ${_proposalBalance}`);
  
    // Deploy LoanContract by signing off loan proposal
    let _tx = await loanProposal
      .connect(lender)
      .setLender(tokenContract.address, tokenId, loanId, { value: loanPrincipal });
    _proposalBalance = await provider.getBalance(loanProposal.address);
    console.log(`New proposal balance: ${_proposalBalance}`);

    _tx = await loanProposal
      .connect(borrower)
      .sign(tokenContract.address, tokenId, loanId);      
    _borrowerBalance = await provider.getBalance(borrower.address);
    _proposalBalance = await provider.getBalance(loanProposal.address);
    console.log(`Final borrower balance: ${_borrowerBalance}`);
    console.log(`Final proposal balance: ${_proposalBalance}`);

    // Test LoanContractDeployed event output
    let [_loanContractAddress, _borrowerAddress, _lenderAddress, _tokenContractAddress, _tokenId] = await listenerLoanContractDeployed(_tx, loanProposal);
    expect(_borrowerAddress).to.equal(borrower.address, "The borrower address does not match.");
    expect(_lenderAddress).to.equal(lender.address, "The lender address does not match.");
    expect(_tokenContractAddress).to.equal(tokenContract.address, "The token contract address does not match.");
    expect(_tokenId).to.equal(tokenId, "The token ID does not match.");

    // Test LoanContract storage values
    let loanContract = await ethers.getContractAt("LoanContract", _loanContractAddress);
    let results = await getLoanContractStateVars(loanContract.address);
    // console.log(`prev prop balance: ${_prevProposalBalance}`)
    // console.log(`new prop balance: ${_newProposalBalance}`)
    expect(results.borrower).to.equal(borrower.address, "The borrower address does not match.");
    expect(results.lender).to.equal(lender.address, "The lender address does not match.");
    expect(results.tokenContract).to.equal(tokenContract.address, "The token contract address does not match");
    expect(results.tokenId).to.equal(tokenId, "The token ID does not match.");
    expect(results.priority).to.equal(loanExpectedPriority, "The priority does not match.");
    assert.isTrue(loanPrincipal.eq(results.principal), "The principal does not match.");
    expect(results.fixedInterestRate).to.equal(loanFixedInterestRate, "The fixed interest rate does not match.");
    expect(results.duration).to.equal(loanDuration, "The duration does not match.");
    expect(results.balance).to.equal(0, "The balance does not match.");
    // assert.isTrue(_newBorrowerBalance.gt(_prevBorrowerBalance), "The borrower's new balance is not greater than before.");
    assert.isTrue(_prevProposalBalance.gt(_newProposalBalance), "The proposals's previous balance is not greater than before.");
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
