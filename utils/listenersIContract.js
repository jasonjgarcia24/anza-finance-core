const eventHandler = require("./eventsHandler");

const listenerLoanContractCreated = async (tx, contract) => {
    const event = await eventHandler(tx, contract, 'LoanContractCreated');

    const loanContract = event.args['loanContract'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];

    return [loanContract, tokenContract, tokenId];
};

module.exports = {
    listenerLoanContractCreated
};