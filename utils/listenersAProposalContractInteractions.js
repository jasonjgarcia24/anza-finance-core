const eventHandler = require("./eventsHandler");

const listenerLoanContractDeployed = async (tx, contractLoanProposal) => {
    const event = await eventHandler(tx, contractLoanProposal, 'LoanContractDeployed');

    const loanContract = event.args['loanContract'];
    const borrower = event.args['borrower'];
    const lender = event.args['lender'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];

    return [loanContract, borrower, lender, tokenContract, tokenId];
}

module.exports = {
    listenerLoanContractDeployed
};