const { assert, expect } = require("chai");
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { ethers, network } = require("hardhat");
const { TRANSFERIBLES, ROLES, LOANSTATE, DEFAULT_TEST_VALUES } = require("../config");
const { reset } = require("./resetFork");
const { impersonate } = require("./impersonate");
const { deploy } = require("../scripts/deploy");
const { listenerLoanActivated } = require("../anza/src/utils/events/listenersLoanContract");
const { listenerLoanContractCreated } = require("../anza/src/utils/events/listenersLoanContractFactory");
const { listenerTermsChanged } = require("../anza/src/utils/events/listenersAContractManager");
const { listenerLoanStateChanged } = require("../anza/src/utils/events/listenersAContractGlobals");
const { listenerDeposited, listenerWithdrawn } = require("../anza/src/utils/events/listenersAContractTreasurer");

let BlockTime;
let LoanContractFactory, LoanContract, LoanTreasurey;
let owner, borrower, lender, lenderAlt, treasurer;
let tokenContract, tokenId;

const loanPrincipal = DEFAULT_TEST_VALUES.PRINCIPAL;
const loanFixedInterestRate = DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE;
const loanDuration = DEFAULT_TEST_VALUES.DURATION;

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
      LoanContractFactory,
      LoanContract,
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
    let [clone, ...__] = await listenerLoanContractCreated(_tx, LoanContractFactory);
  
    // Connect LoanContract
    LoanContract = await ethers.getContractAt("LoanContract", clone, borrower);
  });

  it("0-0-99 :: PASS", async function () {});

  it("0-0-00 :: Verify LoanContract initializer", async function () {
    let _borrower, _tokenContractAddress, _tokenId, _lender, _principal, _fixedInterestRate, _duration, _borrowerSigned, _lenderSigned;

    specify("Verify LoanProposal getter functions", async function () {
      _borrower = (await LoanContract.loanParticipants())['borrower'];
      _tokenContractAddress = (await LoanContract.loanParticipants())['tokenContract'];
      _tokenId = (await LoanContract.loanParticipants())['tokenId'];
      _lender = (await LoanContract.loanProperties())['lender']['_value'];
      _principal = (await LoanContract.loanProperties())['principal']['_value'];
      _fixedInterestRate = (await LoanContract.loanProperties())['fixedInterestRate']['_value'];
      _duration = (await LoanContract.loanProperties())['duration']['_value'];
      _borrowerSigned = (await LoanContract.loanProperties())['borrowerSigned']['_value'];
      _lenderSigned = (await LoanContract.loanProperties())['lenderSigned']['_value'];
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
    });

    specify("Verify roles", async function () {
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._ADMIN_ROLE_, LoanContract.address),
        "The loan contract is not set with ADMIN role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._TREASURER_ROLE_, LoanTreasurey.address),
        "The loan contract is not set with TREASURER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLECTOR_ROLE_, LoanCollection.address),
        "The loan contract is not set with COLLECTOR role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._ARBITER_ROLE_, LoanContract.address),
        "The loan contract is not set with ARBITER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._BORROWER_ROLE_, borrower.address),
        "The borrower is not set with BORROWER role."
      );
      await assert.eventually.isFalse(
        LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address),
        "The loan contract is set with COLLATERAL_OWNER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, LoanContract.address),
        "The loan contract is set with COLLATERAL_CUSTODIAN role."
      );
      await assert.eventually.isFalse(
        LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, borrower.address),
        "The borrower is set with COLLATERAL_CUSTODIAN role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, borrower.address),
        "The borrower is not set with PARTICIPANT role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address),
        "The borrower is not set with COLLATERAL_OWNER role."
      );
      await assert.eventually.isTrue(
        LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, LoanContract.address),
        "The loan contract is not set with COLLATERAL_CUSTODIAN role."
      );
    });
    
    specify("Verify collateral's owner and approver status", async function () {
      await expect(tokenContract.ownerOf(tokenId)).to.eventually.equal(
        LoanContract.address,
        "The LoanContract must be the token owner."
      );
      await expect(tokenContract.getApproved(tokenId)).to.eventually.equal(
        ethers.constants.AddressZero,
        "There must be no token approver."
      );
    });
  });

  it("0-0-01 :: Verify LoanContract NFT withdrawal when state is UNSPONSORED", async function () {
    let _tx, _prevLoanState, _newLoanState, _owner;

    specify("Borrower withdraws LoanContract and LoanContract transfers NFT to borrower", async function () {
      _tx = await LoanContract.connect(borrower).withdrawNft();
      [_prevLoanState,] = await listenerLoanStateChanged(_tx, LoanContract);
      [, _newLoanState] = await listenerLoanStateChanged(_tx, LoanContract, false);
      _owner = await tokenContract.ownerOf(tokenId);

      expect(_prevLoanState).to.equal(LOANSTATE.UNSPONSORED, "The previous loan state must be UNSPONSORED.");
      expect(_newLoanState).to.equal(LOANSTATE.NONLEVERAGED, "The new loan state must be NONLEVERAGED.");
      expect(_owner).to.equal(borrower.address, "The token owner should be the borrower.");
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, LoanContract.address), "The borrower is not set with COLLATERAL_OWNER role.");
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, LoanContract.address), "The borrower is not set with COLLATERAL_OWNER role.");
      await assert.eventually.isTrue(LoanContract.hasRole(ROLES._COLLATERAL_OWNER_ROLE_, borrower.address), "The borrower is not set with COLLATERAL_OWNER role.");
      await assert.eventually.isTrue(LoanContract.hasRole(ROLES._COLLATERAL_CUSTODIAN_ROLE_, borrower.address), "The borrower is not set with COLLATERAL_OWNER role.");
    });
  });

  it("0-0-02 :: Verify LoanContract borrower signoffs", async function () {
    let _tx, _prevLoanState, _newLoanState, _owner

    // Borrower withdraws LoanContract and LoanContract transfers NFT to borrower
    _tx = await LoanContract.connect(borrower).withdrawNft();
    
    specify("Borrower signs LoanContract and transfers NFT to LoanProposal", async function () {
      await tokenContract.setApprovalForAll(LoanContract.address, true);
      _tx = await LoanContract.connect(borrower).sign();
      [_prevLoanState,] = await listenerLoanStateChanged(_tx, LoanContract);
      [, _newLoanState] = await listenerLoanStateChanged(_tx, LoanContract, false);
      _owner = await tokenContract.ownerOf(tokenId);

      expect(_prevLoanState).to.equal(LOANSTATE.NONLEVERAGED, "The previous loan state must be NONLEVERAGED.");
      expect(_newLoanState).to.equal(LOANSTATE.UNSPONSORED, "The new loan state must be UNSPONSORED.");
      expect(_owner).to.equal(LoanContract.address, "The token owner should be the LoanContract.");
    });
  });

  it("0-0-03 :: Verify LoanContract setLender function", async function () {
    let _tx, _prevLoanState, _newLoanState, _payee, _weiAmount, _lender;

    // Remove collateral leveraged
    await LoanContract.withdrawNft();

    specify("Set lender with lender", async function () {
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");

      _tx = await LoanContract.connect(lender).setLender({ value: loanPrincipal });
      await assert.eventually.isTrue(LoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");

      [_prevLoanState,] = await listenerLoanStateChanged(_tx, LoanContract);
      [, _newLoanState] = await listenerLoanStateChanged(_tx, LoanContract, false);
      [_payee, _weiAmount] = await listenerDeposited(_tx, LoanContract);
      expect(_prevLoanState).to.equal(LOANSTATE.NONLEVERAGED, "The previous loan state should be NONLEVERAGED.");
      expect(_newLoanState).to.equal(LOANSTATE.FUNDED, "The new loan state should be FUNDED.");
      expect(_payee).to.equal(lender.address, "The payee should be the lender.");
      expect(_weiAmount.eq(loanPrincipal)).to.equal(true, `The deposited amount should be ${loanPrincipal} WEI.`);

      await assert.eventually.isTrue(LoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");
      await assert.eventually.isTrue(LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender not is set with PARTICIPANT role.");
    });

    specify("Attempt to steal sponsorship", async function () {
      await expect(LoanContract.connect(lenderAlt).setLender(
        { value: loanPrincipal }
      )).to.be.rejectedWith(/The lender must not currently be signed off./);
    });

    specify("Remove lender with borrower", async function () {
      _tx = await LoanContract.setLender();
      [_prevLoanState,] = await listenerLoanStateChanged(_tx, LoanContract);
      [, _newLoanState] = await listenerLoanStateChanged(_tx, LoanContract, false);
      _lender = (await LoanContract.loanProperties())['lender']['_value'];
      expect(_prevLoanState).to.equal(LOANSTATE.FUNDED, "The previous loan state should be FUNDED.");
      expect(_newLoanState).to.equal(LOANSTATE.UNSPONSORED, "The new loan state should be UNSPONSORED.");
      expect(_lender).to.equal(ethers.constants.AddressZero, "The lender is not set to AddressZero.");
      
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
      await assert.eventually.isTrue(LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender not is set with PARTICIPANT role.");
    });

    specify("Remove lender with lender", async function () {
      await LoanContract.connect(lender).setLender();
      _tx = await LoanContract.connect(lender).withdrawSponsorship();
      [_prevLoanState,] = await listenerLoanStateChanged(_tx, LoanContract);
      [, _newLoanState] = await listenerLoanStateChanged(_tx, LoanContract, false);
      expect(_prevLoanState).to.equal(LOANSTATE.FUNDED, "The previous loan state should be FUNDED.");
      expect(_newLoanState).to.equal(LOANSTATE.UNSPONSORED, "The new loan state should be UNSPONSORED.");

      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");
    });

    specify("Set lender with lender with collateral leveraged", async function () {
      await tokenContract.approve(LoanContract.address, tokenId);
      await LoanContract.sign();
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is set with LENDER role.");
      await assert.eventually.isFalse(LoanContract.hasRole(ROLES._PARTICIPANT_ROLE_, lender.address), "The lender is set with PARTICIPANT role.");

      _tx = await LoanContract.connect(lender).setLender({ value: loanPrincipal });
      await assert.eventually.isTrue(LoanContract.hasRole(ROLES._LENDER_ROLE_, lender.address), "The lender is not set with LENDER role.");

      [_prevLoanState,] = await listenerLoanStateChanged(_tx, LoanContract);
      [, _newLoanState] = await listenerLoanStateChanged(_tx, LoanContract, false);
      [_payee, _weiAmount] = await listenerDeposited(_tx, LoanContract);
      expect(_prevLoanState).to.equal(LOANSTATE.UNSPONSORED, "The previous loan state should be UNSPONSORED.");
      expect(_newLoanState).to.equal(LOANSTATE.ACTIVE_OPEN, "The new loan state should be ACTIVE_OPEN.");
      expect(_payee).to.equal(lender.address, "The payee should be the lender.");
      expect(_weiAmount.eq(loanPrincipal)).to.equal(true, `The deposited amount should be ${loanPrincipal} WEI.`);
    });
  });

  it("0-0-04 :: Verify LoanContract updateTerms function for single changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    let _loanPrincipal, _loanFixedInterestRate, _loanDuration, _params, _prevValues, _newValues;

    specify("Collect and check original loan terms", async function () {
      _loanPrincipal = (await LoanContract.loanProperties())['principal']['_value'];
      _loanFixedInterestRate = (await LoanContract.loanProperties())['fixedInterestRate']['_value'];
      _loanDuration = (await LoanContract.loanProperties())['duration']['_value'];
      _loanDuration = await BlockTime.blocksToDays(_loanDuration);
      expect(_loanPrincipal).to.equal(loanPrincipal, "The loan principal is not set as expected.");
      expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
      expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan duration is not set as expected.");
    });

    specify("Update loan principal", async function () {
      _tx = await LoanContract.updateTerms(['principal'], [_newLoanPrincipal]);
      _loanPrincipal = (await LoanContract.loanProperties())['principal']['_value'];
      _loanFixedInterestRate = (await LoanContract.loanProperties())['fixedInterestRate']['_value'];
      _loanDuration = (await LoanContract.loanProperties())['duration']['_value'];
      _loanDuration = await BlockTime.blocksToDays(_loanDuration);
      expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
      expect(_loanFixedInterestRate).to.equal(loanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
      expect(_loanDuration).to.equal(loanDuration, "The loan duration is not set as expected.");

      [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, LoanContract);
      expect('principal').to.equal(_params[0], "Emitted event params incorrect.");
      expect(_prevValues[0].toNumber()).to.equal(loanPrincipal, "Emitted event previous principal value incorrect.");
      expect(_newValues[0].toNumber()).to.equal(_newLoanPrincipal, "Emitted event new principal value incorrect.");
    });

    specify("Update loan fixed interest rate", async function () {
      _tx = await LoanContract.updateTerms(['fixed_interest_rate'], [_newLoanFixedInterestRate]);
      _loanPrincipal = (await LoanContract.loanProperties())['principal']['_value'];
      _loanFixedInterestRate = (await LoanContract.loanProperties())['fixedInterestRate']['_value'];
      _loanDuration = (await LoanContract.loanProperties())['duration']['_value'];
      _loanDuration = await BlockTime.blocksToDays(_loanDuration);
      expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
      expect(_loanFixedInterestRate).to.equal(_newLoanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
      expect(_loanDuration).to.equal(loanDuration, "The loan duration is not set as expected.");

      [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, LoanContract);
      expect('fixed_interest_rate').to.equal(_params[0], "Emitted event params incorrect.");
      expect(_prevValues[0].toNumber()).to.equal(loanFixedInterestRate, "Emitted event previous fixed interest rate value incorrect.");
      expect(_newValues[0].toNumber()).to.equal(_newLoanFixedInterestRate, "Emitted event new fixed interest rate value incorrect.");
    });

    specify("Update loan duration", async function () {
      _tx = await LoanContract.updateTerms(['duration'], [_newLoanDuration]);
      _loanPrincipal = (await LoanContract.loanProperties())['principal']['_value'];
      _loanFixedInterestRate = (await LoanContract.loanProperties())['fixedInterestRate']['_value'];
      _loanDuration = (await LoanContract.loanProperties())['duration']['_value'];
      _loanDuration = await BlockTime.blocksToDays(_loanDuration);
      expect(_loanPrincipal).to.equal(_newLoanPrincipal, "The loan principal is not set as expected.");
      expect(_loanFixedInterestRate).to.equal(_newLoanFixedInterestRate, "The loan fixed interest rate is not set as expected.");
      expect(_loanDuration).to.equal(_newLoanDuration, "The loan duration is not set as expected.");

      [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, LoanContract);
      expect('duration').to.equal(_params[0], "Emitted event params incorrect.");
      await expect(BlockTime.blocksToDays(_prevValues[0].toNumber())).to.eventually.equal(loanDuration, "Emitted event previous duration value incorrect.");
      await expect(BlockTime.blocksToDays(_newValues[0].toNumber())).to.eventually.equal(_newLoanDuration, "Emitted event new duration value incorrect.");
    });
  });

  it("0-0-05 :: Verify LoanContract updateTerms function for multiple changes", async function () {
    const _newLoanPrincipal = 5000;
    const _newLoanFixedInterestRate = 33;
    const _newLoanDuration = 60;

    let _loanPrincipal, _loanFixedInterestRate, _loanDuration, _tx, _params, _prevValues, _newValues

    specify("Collect and check original loan terms", async function () {
      _loanPrincipal = (await LoanContract.loanProperties())['principal']['_value'];
      _loanFixedInterestRate = (await LoanContract.loanProperties())['fixedInterestRate']['_value'];
      _loanDuration = (await LoanContract.loanProperties())['duration']['_value'];
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
      _tx = await LoanContract.updateTerms(
        ['principal', 'duration', 'fixed_interest_rate'],
        [_newLoanPrincipal, _newLoanDuration, _newLoanFixedInterestRate],
      );
    });

    specify("Verify loan parameters using getter functions", async function () {
      _loanPrincipal = (await LoanContract.loanProperties())['principal']['_value'];
      _loanFixedInterestRate = (await LoanContract.loanProperties())['fixedInterestRate']['_value'];
      _loanDuration = (await LoanContract.loanProperties())['duration']['_value'];
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
    });

    specify("Verify loan parameters using emitted events", async function () {
      [_params, _prevValues, _newValues] = await listenerTermsChanged(_tx, LoanContract);
      expect(_prevValues[0].toNumber()).to.equal(loanPrincipal, "Emitted event previous principal value incorrect.");
      expect(_newValues[0].toNumber()).to.equal(_newLoanPrincipal, "Emitted event new principal value incorrect.");
      expect(_prevValues[2].toNumber()).to.equal(loanFixedInterestRate, "Emitted event previous fixed interest rate value incorrect.");
      expect(_newValues[2].toNumber()).to.equal(_newLoanFixedInterestRate, "Emitted event new fixed interest rate value incorrect.");
      await expect(BlockTime.blocksToDays(_prevValues[1])).to.eventually.equal(loanDuration, "Emitted event previous duration value incorrect.");
      await expect(BlockTime.blocksToDays(_newValues[1])).to.eventually.equal(_newLoanDuration, "Emitted event new duration value incorrect.");
    });
  });

  it("0-0-06 :: Verify LoanContract activation on borrower sign", async function () {
    // Unsign borrower
    await LoanContract.withdrawNft();

    // Sign lender
    await LoanContract.connect(lender).setLender({ value: loanPrincipal });

    specify("Activation on borrower signoff", async function () {
      await tokenContract.approve(LoanContract.address, tokenId);
      let _tx = await LoanContract.sign();
      let [_loanContractAddress, _borrowerAddress, _lenderAddress, _tokenContractAddress, _tokenId, _loanState] = await listenerLoanActivated(_tx, LoanContract);
      expect(_loanContractAddress).to.equal(LoanContract.address, "The loan contract address is not expected.");
      expect(_borrowerAddress).to.equal(borrower.address, "The borrower address is not expected.");
      expect(_lenderAddress).to.equal(lender.address, "The lender address is not expected.");
      expect(_tokenContractAddress).to.equal(tokenContract.address, "The token contract is not expected.");
      expect(_tokenId).to.equal(tokenId, "The token ID is not expected.");
      expect(_loanState).to.equal(LOANSTATE.ACTIVE_OPEN, "The loan state is not expected.");
    });
  });

  it("0-0-07 :: Verify LoanContract activation on lender sign", async function () {
    specify("Activation on lender signoff", async function () {
      let _tx = await LoanContract.connect(lender).setLender({ value: loanPrincipal });
      let [_loanContractAddress, _borrowerAddress, _lenderAddress, _tokenContractAddress, _tokenId, _loanState] = await listenerLoanActivated(_tx, LoanContract);
      expect(_loanContractAddress).to.equal(LoanContract.address, "The loan contract address is not expected.");
      expect(_borrowerAddress).to.equal(borrower.address, "The borrower address is not expected.");
      expect(_lenderAddress).to.equal(lender.address, "The lender address is not expected.");
      expect(_tokenContractAddress).to.equal(tokenContract.address, "The token contract is not expected.");
      expect(_tokenId).to.equal(tokenId, "The token ID is not expected.");
      expect(_loanState).to.equal(LOANSTATE.ACTIVE_OPEN, "The loan state is not expected.");
    });
  });

  it("0-0-08 :: Need to test withdrawFunds()", async function () {});
  it("0-0-09 :: Need to test close()", async function () {});
});
