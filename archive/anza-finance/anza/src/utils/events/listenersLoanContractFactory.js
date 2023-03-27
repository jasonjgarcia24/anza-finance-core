const eventHandler = require("./eventsHandler");

const listenerLoanContractCreated = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'LoanContractCreated', first);

    const loanContract = event.args['loanContract'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];

    return [loanContract, tokenContract, tokenId];
};

module.exports = {
    listenerLoanContractCreated
};