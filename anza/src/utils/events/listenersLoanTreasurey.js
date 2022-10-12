const eventHandler = require("./eventsHandler");

const listenerDebtTokenIssued = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'DebtTokenIssued', first);

    const loanContract = event.args['loanContract'];
    const debtTokenAddress = event.args['debtTokenAddress'];
    const debtTokenId = event.args['debtTokenId'];
    const tokenContractAddress = event.args['tokenContractAddress'];

    return [loanContract, debtTokenAddress, debtTokenId, tokenContractAddress];
}

module.exports = {
    listenerDebtTokenIssued
}