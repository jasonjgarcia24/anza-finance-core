const eventHandler = require("./eventsHandler");

const listenerMint = async (tx, contract, first=true) => {
    const event = await eventHandler(tx, contract, 'Mint', first);

    const owner = event.args['owner'];
    const tokenContract = event.args['tokenContract'];
    const tokenId = event.args['tokenId'];

    return [owner, tokenContract, tokenId];
}

module.exports = {
    listenerMint
};