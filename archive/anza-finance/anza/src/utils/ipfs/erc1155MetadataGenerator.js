const { ethers } = require("ethers");
const abi_ERC721Metadata = require("../../artifacts/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol/IERC721Metadata.json");

const generateERC1155Metadata = async (debtObj, loanContractObj) => {
    const { ethereum } = window;
    const provider = new ethers.providers.Web3Provider(ethereum);
    
    const ERC721Metadata = new ethers.Contract(
        loanContractObj.collateralTokenAddress,
        abi_ERC721Metadata.abi,
        provider
    );
    const collateralName = await ERC721Metadata.name();
    const collateralSymbol = await ERC721Metadata.symbol();
    const collateralTokenURI = await ERC721Metadata.tokenURI(loanContractObj.collateralTokenId);

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
                "name": collateralName,
                "symbol": collateralSymbol,
                "tokenURI": collateralTokenURI
            }
        }
    }
}

module.exports = { generateERC1155Metadata };
