const eventHandler = require("./eventsHandler");

const listenerLoanProposalCreated = async (tx, contractLoanProposal) => {
    const event = await eventHandler(tx, contractLoanProposal, 'LoanProposalCreated');

    // console.log(tx)
    const loanId = event.args['loanId'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];

    return [loanId, tokenContract, tokenId];
}

module.exports = {
    listenerLoanProposalCreated
};