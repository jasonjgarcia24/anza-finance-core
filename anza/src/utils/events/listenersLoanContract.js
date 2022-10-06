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

module.exports = {
    listenerLoanActivated
};