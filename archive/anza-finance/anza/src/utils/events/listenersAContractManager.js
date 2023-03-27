const eventHandler = require("./eventsHandler");

const listenerTermsChanged = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'TermsChanged', first);

    const params = event.args['params'];
    const prevValues = event.args['prevValues'];
    const newValues = event.args['newValues'];

    return [params, prevValues, newValues];
};

module.exports = {
    listenerTermsChanged
};