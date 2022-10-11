const eventHandler = require("./eventsHandler");

const listenerLoanActivated = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'LoanActivated', first);

    const loanContract = event.args['loanContract'];
    const borrower = event.args['borrower'];
    const lender = event.args['lender'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];
    const state = event.args['state'];

    return [loanContract, borrower, lender, tokenContract, tokenId, state];
}

const listenerDebtTokenIssued = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'DebtTokenIssued', first);
    console.log(event)

    const loanContract = event.args['loanContract'];
    const debtTokenAddress = event.args['debtTokenAddress'];
    const debtTokenId = event.args['debtTokenId'];
    const tokenContractAddress = event.args['tokenContractAddress'];

    return [loanContract, debtTokenAddress, debtTokenId, tokenContractAddress];
}

module.exports = {
    listenerLoanActivated,
    listenerDebtTokenIssued
};