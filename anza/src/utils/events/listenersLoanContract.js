const eventHandler = require("./eventsHandler");

const listenerLoanContractInit = async (tx, contract, first = true) => {
    const event = await eventHandler(tx, contract, 'LoanContractInitialized', first);

    const collateralAddress = event.args['collateralAddress'];
    const collateralId = event.args['collateralId'];
    const debtId = event.args['debtId'];
    const activeLoanIndex = event.args['activeLoanIndex'];

    return [collateralAddress, collateralId, debtId, activeLoanIndex];
};

module.exports = {
    listenerLoanContractInit
};