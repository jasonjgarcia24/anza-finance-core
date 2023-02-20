const generateERC1155Metadata = async (debtObj, loanContractObj) => {
    return {
        "name": debtObj.name,
        "description": debtObj.description,
        "image": `${debtObj.imageLocation}\/${debtObj.tokenId}`,
        "properties": {
            "symbol": debtObj.symbol,
            "debtId": debtObj.debtId,
            "loanContract": {
                "ownerAddress": loanContractObj.loanContractAddress,
                "borrowerAddress": loanContractObj.borrowerAddress,
                "collateralTokenAddress": loanContractObj.collateralTokenAddress,
                "collateralTokenId": loanContractObj.collateralTokenId,
                "lenderAddress": loanContractObj.lenderAddress,
                "principal": loanContractObj.principal,
                "fixedInterestRate": loanContractObj.fixedInterestRate,
                "duration": loanContractObj.duration,
            },
            "collateral": {
                "name": 'DemoToken',
                "symbol": 'DT',
                "tokenURI": ''
            }
        }
    }
}

module.exports = { generateERC1155Metadata };
