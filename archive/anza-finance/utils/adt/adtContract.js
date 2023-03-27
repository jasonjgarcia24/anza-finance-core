const { ethers, network } = require('hardhat');
const { listenerDebtTokenIssued } = require('../../anza/src/utils/events/listenersLoanTreasurey');
const { listenerURI } = require('../../anza/src/utils/events/listenersAnzaDebtToken');
const config = require('../../anza/src/config.json');
const abi_LoanTreasurey = require('../../anza/src/artifacts/contracts/social/LoanTreasurey.sol/LoanTreasurey.json');
const abi_AnzaDebtToken = require('../../anza/src/artifacts/contracts/social/AnzaDebtToken.sol/AnzaDebtToken.json');

const mintAnzaDebtToken = async (
    account, recipient, treasureyAddress, loanContractAddress, debtTokenURI
) => {
    provider = new ethers.providers.Web3Provider(network.provider);
    const signer = provider.getSigner(account);

    const AnzaDebtToken = new ethers.Contract(
        config.AnzaDebtToken,
        abi_AnzaDebtToken.abi,
        provider
    );

    const LoanTreasurey = new ethers.Contract(
        treasureyAddress,
        abi_LoanTreasurey.abi,
        signer
    );
    const tx = await LoanTreasurey.issueDebtToken(loanContractAddress, recipient, debtTokenURI);
    await tx.wait();

    const [, debtTokenAddress, debtTokenId,] = await listenerDebtTokenIssued(tx, LoanTreasurey);
    [debtTokenURI,] = await listenerURI(tx, AnzaDebtToken);
    
    return [debtTokenAddress, debtTokenId.toString(), debtTokenURI];
}

module.exports = {
    mintAnzaDebtToken
}