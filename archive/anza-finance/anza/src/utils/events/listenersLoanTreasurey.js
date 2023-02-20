const eventHandler = require("./eventsHandler");

const listenerDebtTokenIssued = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'DebtTokenIssued', first);

    const from = event.args['from'];
    const debtTokenAddress = event.args['debtTokenAddress'];
    const debtTokenId = event.args['debtTokenId'];
    const to = event.args['to'];

    return [from, debtTokenAddress, debtTokenId, to];
}

module.exports = {
    listenerDebtTokenIssued
}