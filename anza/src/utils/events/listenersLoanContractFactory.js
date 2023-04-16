const eventHandler = require("./eventsHandler");

const listenerLoanContractInit = async (tx, contract, first = true) => {
    const event = await eventHandler(tx, contract, 'LoanContractCreated', first);

    const collateralAddress = event.args['collateralAddress'];
    const collateralId = event.args['collateralId'];
    const debtId = event.args['debtId'];

    return [collateralAddress, collateralId, debtId];
};

module.exports = {
    listenerLoanContractInit
};