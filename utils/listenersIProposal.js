const eventHandler = require("./eventsHandler");

const listenerLoanLenderChanged = async (tx, contractLoanProposal) => {
    const event = await eventHandler(tx, contractLoanProposal, 'LoanLenderChanged');

    const prevLender = event.args['prevLender'];
    const newLender = event.args['newLender'];

    return [prevLender, newLender];
};

const listenerLoanParamChanged = async (tx, contractLoanProposal) => {
    const event = await eventHandler(tx, contractLoanProposal, 'LoanParamChanged');
    const param = event.args['param'];
    const prevValue = event.args['prevValue'];
    const newValue = event.args['newValue'];

    return [param, prevValue, newValue];
}

const listenerLoanContractCreated = async (tx, contract) => {
    const event = await eventHandler(tx, contract, 'LoanContractCreated');

    const loanContract = event.args['loanContract'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];

    return [loanContract, tokenContract, tokenId];
};

module.exports = {
    listenerLoanContractCreated,
    listenerLoanLenderChanged,
    listenerLoanParamChanged
};