const eventHandler = require("./eventsHandler");

const listenerTransferSingle = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'TransferSingle', first);

    const operator = event.args['operator'];
    const from = event.args['from'];
    const to = event.args['to'];
    const id = event.args['id'];
    const value = event.args['value'];

    return [operator, from, to, id, value];
}

const listenerURI = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'URI', first);

    const value = event.args['value'];
    const id = event.args['id'];

    return [value, id];
}

module.exports = {
    listenerTransferSingle,
    listenerURI
};