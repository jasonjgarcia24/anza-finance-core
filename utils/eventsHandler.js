const eventHandler = async (tx, contract, eventStr, first = true) => {
    const topic = contract.interface.getEventTopic(eventStr);
    const receipt = await tx.wait();
    const logs = first ? receipt.logs : receipt.logs.reverse();
    const log = logs.find(x => x.topics.indexOf(topic) >= 0);
    const event = contract.interface.parseLog(log);

    return event;
}

module.exports = eventHandler;