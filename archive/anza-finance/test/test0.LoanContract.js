const { assert, expect } = require("chai")
const { ethers, network } = require("hardhat");
require("@nomicfoundation/hardhat-chai-matchers")

const { deploy } = require("../script_hh/deploy");

let owner, admin, treasurer, collector, borrower, lender;
let alt_account1, alt_account2, alt_account3, alt_account4;
let LoanContract, DemoToken;
let LibLoanContractStates, LibLoanContractIndexer;
let IERC721;

const LoanState = {
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
    COLLECTION: 11,
    AUCTION: 12,
    AWARDED: 13,
    CLOSED: 14,
}

describe("0-0 :: LoanContract initialization tests", function () {
    beforeEach(async function () {
        ({
            owner,
            admin,
            treasurer,
            collector,
            borrower,
            lender,
            alt_account1,
            alt_account2,
            alt_account4,
            alt_account3,
            alt_account1,
            alt_account2,
            LoanContract,
            DemoToken,
            LibLoanContractStates,
            LibLoanContractIndexer
        } = await deploy());
    });

    it("0-0-99 :: PASS", async function () { });

    it("0-0-00 :: Verify borrower proposal submission", async function () {
        const _collateralAddress = DemoToken.address;
        const _collateralId = 1;
        const _principal = 100;
        const _fixedInterestRate = 5;
        const _duration = 365;
        const _stopBlockstamp = 555;

        let _tx = await DemoToken.approve(LoanContract.address, _collateralId);
        let _receipt = await _tx.wait();

        _tx = await LoanContract.connect(borrower).submitProposal(
            _collateralAddress,
            _collateralId,
            _principal,
            _fixedInterestRate,
            _duration,
            _stopBlockstamp,
        )
        _receipt = await _tx.wait();

        // Check state variables
        const _totalDebtSupply = (await LoanContract.totalDebtSupply(0)).toNumber();
        console.log(_totalDebtSupply);
        // const _debtId = (await LibLoanContractIndexer.currentDebtId(LoanContract.address)).toNumber();
        // const _borrower = await LibLoanContractIndexer["borrower(address,uint256)"](LoanContract.address, _debtId);
        // const _lender = await LibLoanContractIndexer["lender(address,uint256)"](LoanContract.address, _debtId);

        // assert.equal(_debtId, 0, "The debt ID is not zero.");
        // assert.equal(_borrower, borrower.address, "Borrower is not the original collateral owner.");
        // assert.equal(_lender, ethers.constants.AddressZero, "Lender is not address 0.");
        // await assert.eventually.equal(DemoToken.ownerOf(_collateralId), LoanContract.address, "The owner of the collateral is not the loan contract.");
        // await assert.eventually.equal(LoanContract.debtIds(_collateralAddress, _collateralId, _debtId), _debtId, "The debt ID is not consistent.");

        // const _loanState = await LoanContract.loanStates(_debtId);
        // assert.equal(_loanState, LoanState.UNSPONSORED, "The loan state is not UNSPONSORED.");

        // const _token = await LoanContract.tokens(_debtId);
        // assert.equal(_token.collateralAddress._value, _collateralAddress, "The token's collateral address is incorrect.");
        // assert.equal(_token.collateralId._value, _collateralId, "The token's collateralId is incorrect.");
        // assert.equal(_token.principal._value, _principal, "The token's principal is incorrect.");
        // assert.equal(_token.fixedInterestRate._value, _fixedInterestRate, "The token's fixedInterestRate is incorrect.");
        // assert.equal(_token.duration._value, _duration, "The token's duration is incorrect.");
        // assert.equal(_token.unpaidBalance._value, 0, "The token's unpaidBalance is incorrect.");
        // assert.equal(_token.paidBalance._value, 0, "The token's paidBalance is incorrect.");
        // assert.equal(_token.stopBlockstamp._value, _stopBlockstamp, "The token's stopBlockstamp is incorrect.");
        // assert.equal(_token.borrowerSigned._value, true, "The token's borrowerSigned is incorrect.");
        // assert.equal(_token.lenderSigned._value, false, "The token's lenderSigned is incorrect.");

        // let _borrowerALCTokenId = await LibLoanContractIndexer["borrowerToken(address,uint256)"](LoanContract.address, _debtId);
        // let _lenderALCTokenId = await LibLoanContractIndexer["lenderToken(address,uint256)"](LoanContract.address, _debtId);
        // expect(_borrowerALCTokenId).to.equal(_debtId * 2, "The borrower's ALC token ID does is not expected.");
        // expect(_lenderALCTokenId).to.equal((_debtId * 2) + 1, "The lender's ALC token ID does is not expected.");

        // // Check events
        // let _eventTopic = LoanContract.interface.getEventTopic("TokenInitialized")
        // let _eventLog = _receipt.logs.find(x => x.topics.indexOf(_eventTopic) >= 0);
        // let _event = LoanContract.interface.parseLog(_eventLog);

        // expect(_event.args.collateralAddress).to.equal(_collateralAddress, "The collateral address does not match.");
        // expect(_event.args.collateralId).to.equal(_collateralId, "The collateral token ID does not match.");
        // expect(_event.args.debtId.eq(0)).to.equal(true, "The debt ID should be 0.");

        // // ALC toke mints
        // IERC721 = await ethers.getContractAt("IERC721", LoanContract.address, owner);
        // _eventTopic = IERC721.interface.getEventTopic("Transfer")
        // _eventLog = _receipt.logs.filter(x => {
        //     const _isTransfer = x.topics.indexOf(_eventTopic) == 0;
        //     const _couldBeMint = x.topics.indexOf(ethers.constants.HashZero) == 1;

        //     return _isTransfer && _couldBeMint
        // })
        // let _events = _eventLog.map(__event => LoanContract.interface.parseLog(__event));

        // expect(_events[0].args.from).to.equal(ethers.constants.AddressZero, "The from address is not address 0.");
        // expect(_events[0].args.to).to.equal(borrower.address, "The to does not match the borrower.");
        // expect(_events[0].args.tokenId.eq(_borrowerALCTokenId)).to.equal(true, `The token ID should be ${_borrowerALCTokenId}.`);

        // expect(_events[1].args.from).to.equal(ethers.constants.AddressZero, "The from address is not address 0.");
        // expect(_events[1].args.to).to.equal(LoanContract.address, "The to does not match the LoanContract.");
        // expect(_events[1].args.tokenId.eq(_lenderALCTokenId)).to.equal(true, `The token ID should be ${_lenderALCTokenId}.`);
    })

    it("0-0-01 :: Verify borrower withdrawal", async function () {
        const _collateralAddress = DemoToken.address;
        const _collateralId = 1;
        const _principal = 100;
        const _fixedInterestRate = 5;
        const _duration = 365;
        const _stopBlockstamp = 555;

        let _tx = await DemoToken.approve(LoanContract.address, _collateralId);
        let _receipt = await _tx.wait();

        _tx = await LoanContract.connect(borrower).submitProposal(
            _collateralAddress,
            _collateralId,
            _principal,
            _fixedInterestRate,
            _duration,
            _stopBlockstamp,
        )
        _receipt = await _tx.wait();

        const _debtId = (await LibLoanContractIndexer.currentDebtId(LoanContract.address)).toNumber();

        // Withdraw collateral
        _tx = await LoanContract.connect(borrower).withdrawCollateral(_debtId)
        _receipt = await _tx.wait();

        // Check events
        IERC721 = await ethers.getContractAt("IERC721", LoanContract.address, owner);

        let _eventTopic = IERC721.interface.getEventTopic("Transfer")
        let _eventLog = _receipt.logs.find(x => x.topics.indexOf(_eventTopic) >= 0);
        let _event = IERC721.interface.parseLog(_eventLog);

        expect(_event.args.from).to.equal(LoanContract.address, "The from address does not match the LoanContract.");
        expect(_event.args.to).to.equal(borrower.address, "The to does not match the borrower.");
        expect(_event.args.tokenId.eq(_collateralId)).to.equal(true, `The token ID should be ${_collateralId}.`);

        // Check state variables
        const _loanState = await LoanContract.loanStates(_debtId);
        assert.equal(_loanState, LoanState.NONLEVERAGED, "The loan state is not NONLEVERAGED.");
    })

    it("0-0-02 :: Verify lender proposal submission", async function () {
        const _collateralAddress = DemoToken.address;
        const _collateralId = 1;
        const _principal = 100;
        const _fixedInterestRate = 5;
        const _duration = 365;
        const _stopBlockstamp = 555;

        let _tx = await DemoToken.approve(LoanContract.address, _collateralId);
        let _receipt = await _tx.wait();

        _tx = await LoanContract.connect(lender).submitProposal(
            _collateralAddress,
            _collateralId,
            _principal,
            _fixedInterestRate,
            _duration,
            _stopBlockstamp,
            { value: 3 }
        )
        _receipt = await _tx.wait();

        // Check state variables
        const _debtId = (await LibLoanContractIndexer.currentDebtId(LoanContract.address)).toNumber();
        const _borrower = await LibLoanContractIndexer["borrower(address,uint256)"](LoanContract.address, _debtId);
        const _lender = await LibLoanContractIndexer["lender(address,uint256)"](LoanContract.address, _debtId);

        assert.equal(_debtId, 0, "The debt ID is not zero.");
        assert.equal(_borrower, ethers.constants.AddressZero, "Borrower is not address zero.");
        assert.equal(_lender, lender.address, "Lender is not the proposal submitter.");
        await assert.eventually.equal(DemoToken.ownerOf(_collateralId), borrower.address, "The owner of the collateral is not unchanged.");
        await assert.eventually.equal(LoanContract.debtIds(_collateralAddress, _collateralId, _debtId), _debtId, "The debt ID is not consistent.");

        const _loanState = await LoanContract.loanStates(_debtId);
        assert.equal(_loanState, LoanState.NONLEVERAGED, "The loan state is not NONLEVERAGED.");

        const _token = await LoanContract.tokens(_debtId);
        assert.equal(_token.collateralAddress._value, _collateralAddress, "The token's collateral address is incorrect.");
        assert.equal(_token.collateralId._value, _collateralId, "The token's collateralId is incorrect.");
        assert.equal(_token.principal._value, _principal, "The token's principal is incorrect.");
        assert.equal(_token.fixedInterestRate._value, _fixedInterestRate, "The token's fixedInterestRate is incorrect.");
        assert.equal(_token.duration._value, _duration, "The token's duration is incorrect.");
        assert.equal(_token.unpaidBalance._value, 0, "The token's unpaidBalance is incorrect.");
        assert.equal(_token.paidBalance._value, 0, "The token's paidBalance is incorrect.");
        assert.equal(_token.stopBlockstamp._value, _stopBlockstamp, "The token's stopBlockstamp is incorrect.");
        assert.equal(_token.borrowerSigned._value, false, "The token's borrowerSigned is incorrect.");
        assert.equal(_token.lenderSigned._value, true, "The token's lenderSigned is incorrect.");

        let _borrowerALCTokenId = await LibLoanContractIndexer["borrowerToken(address,uint256)"](LoanContract.address, _debtId);
        let _lenderALCTokenId = await LibLoanContractIndexer["lenderToken(address,uint256)"](LoanContract.address, _debtId);
        expect(_borrowerALCTokenId).to.equal(_debtId * 2, "The borrower's ALC token ID does is not expected.");
        expect(_lenderALCTokenId).to.equal((_debtId * 2) + 1, "The lender's ALC token ID does is not expected.");

        // Check events
        let _eventTopic = LoanContract.interface.getEventTopic("TokenInitialized")
        let _eventLog = _receipt.logs.find(x => x.topics.indexOf(_eventTopic) >= 0);
        let _event = LoanContract.interface.parseLog(_eventLog);

        expect(_event.args.collateralAddress).to.equal(_collateralAddress, "The collateral address does not match.");
        expect(_event.args.collateralId).to.equal(_collateralId, "The collateral token ID does not match.");
        expect(_event.args.debtId.eq(0)).to.equal(true, "The debt ID should be 0.");

        // ALC toke mints
        IERC721 = await ethers.getContractAt("IERC721", LoanContract.address, owner);
        _eventTopic = IERC721.interface.getEventTopic("Transfer")
        _eventLog = _receipt.logs.filter(x => {
            const _isTransfer = x.topics.indexOf(_eventTopic) == 0;
            const _couldBeMint = x.topics.indexOf(ethers.constants.HashZero) == 1;

            return _isTransfer && _couldBeMint
        })
        let _events = _eventLog.map(__event => LoanContract.interface.parseLog(__event));

        expect(_events[0].args.from).to.equal(ethers.constants.AddressZero, "The from address is not address 0.");
        expect(_events[0].args.to).to.equal(LoanContract.address, "The to does not match the LoanContract.");
        expect(_events[0].args.tokenId.eq(_borrowerALCTokenId)).to.equal(true, `The token ID should be ${_borrowerALCTokenId}.`);

        expect(_events[1].args.from).to.equal(ethers.constants.AddressZero, "The from address is not address 0.");
        expect(_events[1].args.to).to.equal(lender.address, "The to does not match the lender.");
        expect(_events[1].args.tokenId.eq(_lenderALCTokenId)).to.equal(true, `The token ID should be ${_lenderALCTokenId}.`);
    })

    it("0-0-03 :: Verify non-borrower withdrawal denied", async function () {
        const _collateralAddress = DemoToken.address;
        const _collateralId = 1;
        const _principal = 100;
        const _fixedInterestRate = 5;
        const _duration = 365;
        const _stopBlockstamp = 555;

        let _tx = await DemoToken.approve(LoanContract.address, _collateralId);
        let _receipt = await _tx.wait();

        _tx = await LoanContract.connect(borrower).submitProposal(
            _collateralAddress,
            _collateralId,
            _principal,
            _fixedInterestRate,
            _duration,
            _stopBlockstamp,
        )
        _receipt = await _tx.wait();

        const _debtId = (await LibLoanContractIndexer.currentDebtId(LoanContract.address)).toNumber();

        // Withdraw collateral
        await expect(LoanContract.connect(owner).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(admin).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(treasurer).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(collector).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(lender).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(alt_account1).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(alt_account2).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(alt_account3).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
        await expect(LoanContract.connect(alt_account4).withdrawCollateral(_debtId)).to.be.rejectedWith(/Not authorized for collateral withdrawal/)
    })
})
