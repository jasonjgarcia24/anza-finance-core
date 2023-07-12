import { ethers } from 'ethers';
import config from '../../config.json';

import artifact_AnzaToken from '../../artifacts/AnzaToken.sol/AnzaToken.json';

export const getADTBorrowerOf = async (chainId, debtId) => {
    const { ethereum } = window;
    const provider = new ethers.providers.Web3Provider(ethereum);

    const AnzaDebtToken = new ethers.Contract(
        config[chainId].AnzaToken,
        artifact_AnzaToken.abi,
        provider
    );

    const borrower = await AnzaDebtToken.borrowerOf(debtId);

    return borrower;
}
