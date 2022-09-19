const eventHandler = require("./eventsHandler");

const listenerLoanProposalCreated = async (tx, contractLoanProposal) => {
    const event = eventHandler(tx, contractLoanProposal, 'LoanProposalCreated');

    const loanId = event.args['loanId'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];

    return [loanId, tokenContract, tokenId];
}

module.exports = {
    listenerLoanProposalCreated
};