// import { ethers } from 'ethers';
// import { listenerDebtTokenIssued } from '../events/listenersLoanContract';
// import { listenerURI } from '../events/listenersAnzaDebtToken';
// import config from '../../config.json';
// import abi_LoanContract from '../../artifacts/contracts/social/LoanContract.sol/LoanContract.json';
// import abi_AnzaDebtToken from '../../artifacts/contracts/social/AnzaDebtToken.sol/AnzaDebtToken.json';

export const mintAnzaDebtToken = async (account, cloneAddress, debtTokenURI) => {
    // const { ethereum } = window;
    // const provider = new ethers.providers.Web3Provider(ethereum);
    // const signer = provider.getSigner(account);

    // const AnzaDebtToken = new ethers.Contract(
    //     config.AnzaDebtToken,
    //     abi_AnzaDebtToken.abi,
    //     provider
    // );

    // const LoanContract = new ethers.Contract(
    //     cloneAddress,
    //     abi_LoanContract.abi,
    //     signer
    // );
    // const tx = await LoanContract.issueDebtToken(debtTokenURI);
    // await tx.wait();

    // const [, debtTokenAddress, debtTokenId,] = await listenerDebtTokenIssued(tx, LoanContract);
    // [debtTokenURI,] = await listenerURI(tx, AnzaDebtToken);

    // return [debtTokenAddress, debtTokenId.toString(), debtTokenURI];
}
