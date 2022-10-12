const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES, ROLES, LOANSTATE, DEFAULT_TEST_VALUES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { deploy } = require("../scripts/deploy");
const { mintAnzaDebtToken } = require('../utils/adt/adtContract');
const { listenerLoanContractCreated } = require('../anza/src/utils/events/listenersLoanContractFactory');
const { listenerDebtTokenIssued } = require('../anza/src/utils/events/listenersLoanTreasurey');
const { listenerURI } = require('../anza/src/utils/events/listenersAnzaDebtToken');

let provider;

let BlockTime;
let LoanContractFactory, LoanContract, AnzaDebtToken, LoanTreasurey, LoanCollection;
let ILoanContract;
let owner, borrower, lender, lenderAlt, treasurer;
let tokenContract, tokenId, debtId, tokenURI;
let debtTokenAddress, debtTokenId, debtTokenURI;

const loanPrincipal = DEFAULT_TEST_VALUES.PRINCIPAL;
const loanFixedInterestRate = DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE;
const loanDuration = DEFAULT_TEST_VALUES.DURATION;
const amountDebtTokens = DEFAULT_TEST_VALUES.PRINCIPAL;

describe("2-0 :: AnzaDebtToken init tests", function () {
  /* AnzaDebtToken setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [owner, borrower, lender, lenderAlt, treasurer,] = await ethers.getSigners();
    
    // Establish NFT identifiersl
    tokenContract = new ethers.Contract(
      TRANSFERIBLES[0].nft, TRANSFERIBLES[0].abi, borrower
    );
    tokenId = TRANSFERIBLES[0].tokenId;

    // Create LoanProposal for NFT
    ({
      LoanContractFactory,
      LoanContract,
      AnzaDebtToken,
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
    let [clone,] = await listenerLoanContractCreated(_tx, LoanContractFactory);

    // Activate LoanContract
    LoanContract = await ethers.getContractAt("LoanContract", clone, borrower);
    ILoanContract = await ethers.getContractAt("ILoanContract", clone, borrower);
    _tx = await LoanContract.connect(lender).setLender({ value: loanPrincipal });
    await _tx.wait();
  });

  it("2-0-99 :: PASS", async function () {});

  it("2-0-00 :: Verify AnzaDebtToken issuance events", async function () {
    let _loanTreasureyAddress, _debtTokenAddress, _debtTokenId, _loanContractAddress, _debtTokenURI
    debtTokenURI = 'Qmadfa454jjlhhbhv76lgjjbjvnvasfeijwefoasfjjfadjf';

    const _expectedTokenId = (await LoanContractFactory.getNextDebtId()).toNumber() - 1;

    const AnzaDebtToken_Factory = await ethers.getContractFactory("AnzaDebtToken");
    const AnzaDebtToken = await AnzaDebtToken_Factory.deploy(
      "ipfs://",
      owner.address,
      LoanTreasurey.address
    );
    await AnzaDebtToken.deployed();
    await LoanTreasurey.connect(treasurer).setDebtTokenAddress(AnzaDebtToken.address);

    const tx = await LoanTreasurey.connect(borrower).issueDebtToken(LoanContract.address, debtTokenURI);
    await tx.wait();

    [_loanTreasureyAddress, _debtTokenAddress, _debtTokenId, _loanContractAddress] = await listenerDebtTokenIssued(tx, LoanTreasurey);
    expect(_loanTreasureyAddress).to.equal(LoanTreasurey.address, "LoanTreasurey emitted address unexpected.");
    expect(_debtTokenAddress).to.equal(AnzaDebtToken.address, "AnzaDebtToken emitted address unexpected.");
    expect(_debtTokenId).to.equal(_expectedTokenId, "AnzaDebtToken emitted token ID unexpected.");
    expect(_loanContractAddress).to.equal(LoanContract.address, "LoanContract emitted address unexpected.");

    [_debtTokenURI, _debtTokenId] = await listenerURI(tx, AnzaDebtToken);
    expect(_debtTokenURI).to.equal(`ipfs://${debtTokenURI}`, "AnzaDebtToken emitted URI unexpected.");
    expect(_debtTokenId).to.equal(_expectedTokenId, "AnzaDebtToken emitted token ID unexpected.");
  });

  it("2-0-01 :: Verify AnzaDebtToken issuance only allowed for loan participants", async function () {
    // Attempt issuance by non-participant
    [, debtId,] = await LoanContract.loanGlobals();
    debtTokenURI = 'Qmadfa454jjlhhbhv76lgjjbjvnvasfeijwefoasfjjfadjf';

    await expect(
      mintAnzaDebtToken(
        lenderAlt.address, LoanTreasurey.address, LoanContract.address, debtTokenURI
      )
    ).to.be.rejectedWith(/AccessControl: account .* is missing role/);
  });

  it("2-0-02 :: Verify AnzaDebtToken issuance only allowed when debtTokenAddress state variable set", async function () {
    // LoanTreasurey debtTokenAddress not set
    await LoanTreasurey.connect(treasurer).setDebtTokenAddress(ethers.constants.AddressZero);
    debtTokenURI = 'Qmadfa454jjlhhbhv76lgjjbjvnvasfeijwefoasfjjfadjf';

    await expect(
      mintAnzaDebtToken(
        borrower.address, LoanTreasurey.address, LoanContract.address, debtTokenURI
      )
    ).to.be.rejectedWith('Debt token not set');

    // LoanTreasurey debtTokenAddress set
    await LoanTreasurey.connect(treasurer).setDebtTokenAddress(AnzaDebtToken.address);    
    [debtTokenAddress, debtTokenId, debtTokenURI] = await mintAnzaDebtToken(
      borrower.address, LoanTreasurey.address, LoanContract.address, debtTokenURI
    );

    _balance = await AnzaDebtToken.balanceOf(LoanContract.address, debtTokenId);
    _uri = await AnzaDebtToken.uri(debtTokenId);

    expect(_balance.toNumber()).to.equal(loanPrincipal, 'AnzaDebtToken balance should be equal to the principal.');
    expect(_uri).to.equal(debtTokenURI, 'AnzaDebtToken URI not expected.');
  });
});

describe("2-1 :: AnzaDebtToken post init tests", function () {
  /* AnzaDebtToken setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [owner, borrower, lender, lenderAlt, treasurer,] = await ethers.getSigners();
    
    // Establish NFT identifiersl
    tokenContract = new ethers.Contract(
      TRANSFERIBLES[0].nft, TRANSFERIBLES[0].abi, borrower
    );
    tokenId = TRANSFERIBLES[0].tokenId;

    // Create LoanProposal for NFT
    ({
      LoanContractFactory,
      LoanContract,
      AnzaDebtToken,
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
    let [clone,] = await listenerLoanContractCreated(_tx, LoanContractFactory);

    // Activate LoanContract
    LoanContract = await ethers.getContractAt("LoanContract", clone, borrower);
    ILoanContract = await ethers.getContractAt("ILoanContract", clone, borrower);
    _tx = await LoanContract.connect(lender).setLender({ value: loanPrincipal });
    await _tx.wait();

    // Issue AnzaDebtTokens
    [, debtId,] = await LoanContract.loanGlobals();
    debtTokenURI = 'Qmadfa454jjlhhbhv76lgjjbjvnvasfeijwefoasfjjfadjf';

    [debtTokenAddress, debtTokenId, debtTokenURI] = await mintAnzaDebtToken(
      borrower.address, LoanTreasurey.address, clone, debtTokenURI
    );
  });

  it("2-1-99 :: PASS", async function () {});

  it("2-1-00 :: Verify AnzaDebtToken attributes", async function () {
    let _uri, _balance;
    _balance = await AnzaDebtToken.balanceOf(LoanContract.address, debtTokenId);
    _uri = await AnzaDebtToken.uri(debtTokenId);

    expect(_balance.toNumber()).to.equal(loanPrincipal, "Token balance does not match loan principal.");
    expect(_uri).to.equal(debtTokenURI, "Token URI does not match expected.");
  });

  it("2-1-09 :: Verify lender allowed to exchange ADT for loan payment funds", async function () {});
});

const advanceBlock = async (days) => {  
  let _blocks = await BlockTime.daysToBlocks(days);
  _blocks = _blocks.toNumber();
  _blocks = `0x${_blocks.toString(16)}`;

  await network.provider.send("hardhat_mine", [_blocks]);
}
