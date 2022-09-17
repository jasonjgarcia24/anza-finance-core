const { assert, expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const erc721 = require("../artifacts/@openzeppelin/contracts/token/ERC721/IERC721.sol/IERC721.json").abi;



describe("0-0 :: LoanProposal tests", function () {
  let loanProposal;
  let borrower, lender;
  let tokenContract;
  let tokenId;
  let loanPrincipal = 12345;
  let loanFixedInterestRate = 1;
  let loanDuration = 60;

  /* Setup tokenContract
   *    Ceate tokenContract and mint NFT for borrower.
  **/
  before(async () => {
    [borrower, lender, ..._] = await hre.ethers.getSigners();

    const DemoTokenFactory = await hre.ethers.getContractFactory("DemoToken");
    tokenContract = await DemoTokenFactory.deploy();
    await tokenContract.deployed();

    await tokenContract.mint(borrower.address);
    tokenId = (await tokenContract.getTokenId()).toNumber();
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
  });

  it("0-0-01 :: Test LoanProposal setLender function", async function () {
    
  });
});
