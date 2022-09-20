const eventHandler = require("./eventsHandler");

const listenerLoanSignoffChanged = async (tx, contractLoanProposal) => {
    const event = await eventHandler(tx, contractLoanProposal, 'LoanSignoffChanged');

    const signer = event.args['signer'];
    const action = event.args['action'];
    const borrowerSignStatus = event.args['borrowerSignStatus'];
    const lenderSignStatus = event.args['lenderSignStatus'];

    return [signer, action, borrowerSignStatus, lenderSignStatus];
}

module.exports = {
    listenerLoanSignoffChanged
};