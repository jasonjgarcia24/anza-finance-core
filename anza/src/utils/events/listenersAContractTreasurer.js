const eventHandler = require("./eventsHandler");

const listenerDeposited = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'Deposited', first);

    const payee = event.args['payee'];
    const weiAmount = event.args['weiAmount'];

    return [payee, weiAmount];
};

const listenerWithdrawn = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'Withdrawn', first);

    const payee = event.args['payee'];
    const weiAmount = event.args['weiAmount'];

    return [payee, weiAmount];
};

module.exports = {
    listenerDeposited,
    listenerWithdrawn
};