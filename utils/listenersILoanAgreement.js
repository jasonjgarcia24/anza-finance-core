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

const listenerLoanStateChanged = async (tx, contractLoanProposal) => {
    const event = await eventHandler(tx, contractLoanProposal, 'LoanStateChanged');

    const prevState = event.args['prevState'];
    const newState = event.args['newState'];

    return [prevState, newState];
}

module.exports = {
    listenerLoanLenderChanged,
    listenerLoanParamChanged,
    listenerLoanStateChanged
};