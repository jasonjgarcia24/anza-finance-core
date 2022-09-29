const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES, LOANSTATE } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { listenerLoanActivated } = require("../utils/listenersLoanContract");
const { listenerLoanContractCreated } = require("../utils/listenersLoanContractFactory");
const { listenerTermsChanged } = require("../utils/listenersAContractManager");
const { listenerLoanStateChanged } = require("../utils/listenersAContractGlobals");
const { listenerDeposited, listenerWithdrawn } = require("../utils/listenersAContractTreasurer");

let loanProposal, loanContract;
let blockTime;
let borrower, lender, lenderAlt;
let tokenContract, tokenId;

const loanPrincipal = ethers.utils.parseEther('0.0001');
const loanFixedInterestRate = 23;
const loanDuration = 3;

describe("0 :: LoanContract active state tests", function () {
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
    const StateControlUintFactory = await ethers.getContractFactory("StateControlUint");
    stateControlUint = await StateControlUintFactory.deploy();

    const BlockTimeFactory = await ethers.getContractFactory("BlockTime");
    blockTime = await BlockTimeFactory.deploy();

    const LoanContractFactory = await ethers.getContractFactory("LoanContract", {
      libraries: {
        StateControlUint: stateControlUint.address,
        BlockTime: blockTime.address,
      },
    });
    const LoanProposalFactory = await ethers.getContractFactory("LoanContractFactory");
    loanContract = await LoanContractFactory.deploy();
    loanProposal = await LoanProposalFactory.deploy();
    await loanProposal.deployed();

    // Set loanProposal to operator
    await tokenContract.setApprovalForAll(loanProposal.address, true);

    let _tx = await loanProposal.connect(borrower).createLoanContract(
      loanContract.address,
      tokenContract.address,
      tokenId,
      loanPrincipal,
      loanFixedInterestRate,
      loanDuration
    );
    let [_clone, _tokenContractAddress, _tokenId, _borrower] = await listenerLoanContractCreated(_tx, loanProposal);

    // Connect loanContract
    loanContract = await ethers.getContractAt("LoanContract", _clone, borrower);    
  });

  it("0-1-99 :: PASS", async function () {});

  it("0-1-00 :: Verify loan activation on lender sig", async function () {
    // Sign lender
    let _tx = await loanContract.connect(lender).setLender({ value: loanPrincipal });
    _tx = await loanContract.withdrawFunds();
    let [_payee, _payment] = await listenerWithdrawn(_tx, loanContract)
    expect(_payee).to.equal(borrower.address, "The borrower address is not expected.");
    expect(_payment).to.equal(loanPrincipal, "The withdrawn payment is not expected.");
  });
});
