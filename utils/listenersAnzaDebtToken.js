const eventHandler = require("./eventsHandler");

const listenerAnzaDebtToken = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'TransferSingle', first);

    const operator = event.args['operator'];
    const from = event.args['from'];
    const to = event.args['to'];
    const id = event.args['id'];
    const value = event.args['value'];

    return [operator, from, to, id, value];
}

module.exports = {
    listenerAnzaDebtToken
};