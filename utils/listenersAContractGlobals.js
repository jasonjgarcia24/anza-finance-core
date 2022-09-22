const eventHandler = require("./eventsHandler");

const listenerLoanStateChanged = async (tx, contract) => {
    const event = await eventHandler(tx, contract, 'LoanStateChanged');

    const prevState = event.args['prevState'];
    const newState = event.args['newState'];

    return [prevState, newState];
}

module.exports = {
    listenerLoanStateChanged
};