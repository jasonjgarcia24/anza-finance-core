import { ethers } from 'ethers';
import config from '../../config.json';
import { generateERC1155Metadata } from '../ipfs/erc1155MetadataGenerator';
import { postMetadataIPFS } from '../ipfs/postMetadataIPFS';
import abi_LoanContractFactory from '../../artifacts/contracts/social/LoanContractFactory.sol/LoanContractFactory.json';
import abi_AnzaDebtToken from '../../artifacts/contracts/social/AnzaDebtToken.sol/AnzaDebtToken.json';

export const setAnzaDebtTokenMetadata = async (account, debtId=null) => {
    const { ethereum } = window;
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner(account);

    const LoanContractFactory = new ethers.Contract(
        config.LoanContractFactory,
        abi_LoanContractFactory.abi,
        signer
    );

    const AnzaDebtToken = new ethers.Contract(
        config.AnzaDebtToken,
        abi_AnzaDebtToken.abi,
        provider
    );

    const anzaDebtTokenName = await AnzaDebtToken.name();
    const anzaDebtTokenSymbol = await AnzaDebtToken.symbol();
    debtId = debtId || (await LoanContractFactory.getNextDebtId());

    const debtObj = {
        name: anzaDebtTokenName,
        symbol: anzaDebtTokenSymbol,
        debtId: debtId.toString(),
        description: 'Anza finance debt token',
        imageLocation: ''
    };    

    return debtObj;
}

export const postAnzaDebtTokenIPFS = async (debtObj, loanContractObj) => {
    const debtTokenMetadata = await generateERC1155Metadata(debtObj, loanContractObj);        
    const cid = await postMetadataIPFS(debtTokenMetadata);

    return cid;
}
