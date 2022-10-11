const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES, ROLES, LOANSTATE, DEFAULT_TEST_VALUES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { deploy } = require("../scripts/deploy");
const { listenerLoanContractCreated } = require('../anza/src/utils/events/listenersLoanContractFactory');
const { listenerAnzaDebtToken } = require("../anza/src/utils/events/listenersAnzaDebtToken");
const { generateERC1155Metadata } = require("../anza/src/utils/ipfs/erc1155MetadataGenerator")

let provider;

let BlockTime;
let LoanContractFactory, LoanContract, LoanTreasurey, LoanCollection;
let owner, borrower, lender, lenderAlt, treasurer;
let tokenContract, tokenId, debtId, tokenURI;

const loanPrincipal = DEFAULT_TEST_VALUES.PRINCIPAL;
const loanFixedInterestRate = DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE;
const loanDuration = DEFAULT_TEST_VALUES.DURATION;
const amountDebtTokens = DEFAULT_TEST_VALUES.PRINCIPAL;

tokenURI = '1234asdf5678ghjk9l';

describe("0-3 :: AnzaDebtToken initialization tests", function () {
  /* AnzaDebtToken setup */
  beforeEach(async () => {
    // MAINNET fork setup
    await reset();
    await impersonate();
    provider = new ethers.providers.Web3Provider(network.provider);
    [owner, borrower, lender, lenderAlt, treasurer, ..._] = await ethers.getSigners();
    
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
      LoanTreasurey.address,
      LoanCollection.address,
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
    let [clone, ...__] = await listenerLoanContractCreated(_tx, LoanContractFactory);
  
    // Connect LoanContract
    LoanContract = await ethers.getContractAt("LoanContract", clone, borrower);
    [, debtId,] = await LoanContract.loanGlobals();

    // Mint AnzaDebtTokens
    tx = await AnzaDebtToken.connect(treasurer).mintDebt(
      lender.address,
      clone,
      debtId,
      amountDebtTokens,
      tokenURI
    );

    let [_operator, _from, _to, _id, _value] = await listenerAnzaDebtToken(tx, AnzaDebtToken);

    let debtName = await AnzaDebtToken.name();
    let debtSymbol = await AnzaDebtToken.symbol();

    let debtObj = {
      name: debtName,
      symbol: debtSymbol,
      tokenId: debtId,
      description: 'Anza finance debt token',
      imageLocation: ''
    };

    let loanContractObj = {
      loanContractAddress: clone,
      borrowerAddress: borrower.address,
      collateralTokenAddress: tokenContract.address,
      collateralTokenId: tokenId,
      lenderAddress: lender.address,
      principal: loanPrincipal,
      fixedInterestRate: loanFixedInterestRate,
      duration: loanDuration
    }

    let debtTokenURI = await generateERC1155Metadata(debtObj, loanContractObj)
    console.log(debtTokenURI)
  });

  it("0-3-99 :: PASS", async function () {});

  it("x-3-00 :: Verify loan not default when paid", async function () {
    // // Sign lender and activate loan
    // await LoanContract.connect(lender).setLender({ value: loanPrincipal });
    // await LoanContract.connect(borrower).makePayment({ value: loanPrincipal });

    // // Advance block number
    // await advanceBlock(loanDuration);

    // // Assess maturity
    // let _tx = await LoanTreasurey.connect(treasurer).assessMaturity(LoanContract.address);
    // let _state = (await LoanContract.loanGlobals())['state'];
    // expect(_state).to.equal(LOANSTATE.PAID, "The loan state should be PAID.");
    
    // await expect(
    //   listenerLoanStateChanged(_tx, LoanContract)
    // ).to.be.rejectedWith(/Cannot read properties of undefined/);

    // await assert.eventually.isTrue(
    //   LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
    //   "The borrower is not set with PARTICIPANT_ROLE role."
    // );
    // await assert.eventually.isTrue(
    //   LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
    //   "The borrower is not set with COLLATERAL_OWNER_ROLE role."
    // );
    // await assert.eventually.isFalse(
    //   LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
    //   "The loan contract is set with COLLATERAL_OWNER_ROLE role."
    // );
  });
});

const advanceBlock = async (days) => {  
  let _blocks = await BlockTime.daysToBlocks(days);
  _blocks = _blocks.toNumber();
  _blocks = `0x${_blocks.toString(16)}`;

  await network.provider.send("hardhat_mine", [_blocks]);
}
