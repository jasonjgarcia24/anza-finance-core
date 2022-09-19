const eventHandler = async (tx, contract, eventStr) => {
    const topic = contract.interface.getEventTopic(eventStr);
    const receipt = await tx.wait();
    const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    const event = contract.interface.parseLog(log);  
    
    return event;
}

module.exports = eventHandler;