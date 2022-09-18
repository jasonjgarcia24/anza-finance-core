const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const erc721 = require("../artifacts/@openzeppelin/contracts/token/ERC721/IERC721.sol/IERC721.json").abi;

let loanProposal;
let borrower, lender, approver, operator;
let tokenContract, tokenId;
let loanPrincipal = 1;
let loanFixedInterestRate = 2;
let loanDuration = 3;

describe("0-0 :: LoanProposal tests", function () {
  /* Setup tokenContract
   *    Ceate tokenContract and mint NFT for borrower.
  **/
  before(async () => {
    provider = new ethers.providers.Web3Provider(hre.network.provider);
    [borrower, lender, approver, operator, ..._] = await hre.ethers.getSigners();

    // Deploy NFT contract
    const DemoTokenFactory = await hre.ethers.getContractFactory("DemoToken", borrower);
    tokenContract = await DemoTokenFactory.deploy();
    await tokenContract.deployed();

    // Set operator
    await tokenContract.setApprovalForAll(operator.address, true);

    // Mint NFT
    await tokenContract.mint(borrower.address);
    tokenId = (await tokenContract.getTokenId()).toNumber();

    // Set NFT approver
    await tokenContract.approve(approver.address, tokenId);
  })

  /* Test LoanProposal functions */
  beforeEach(async () => {
    const LoanProposalFactory = await hre.ethers.getContractFactory("LoanProposal");
    loanProposal = await LoanProposalFactory.deploy();

    await loanProposal.connect(borrower).createLoanProposal(
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
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
