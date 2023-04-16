const setAnzaDebtTokenMetadata = async (account, debtId = '0') => {
    const debtObj = {
        name: 'AnzaDebtToken',
        symbol: 'ADT',
        debtId: '0',
        description: 'Anza finance debt token',
        imageLocation: ''
    };

    return debtObj;
}

module.exports = {
    setAnzaDebtTokenMetadata
}
