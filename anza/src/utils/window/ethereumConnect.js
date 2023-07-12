export const checkIfWalletIsConnected = async () => {
    /**
     * Connect wallet state change function.
     */

    // Get wallet's ethereum object
    const { ethereum } = window;

    if (!ethereum) {
        console.log('Make sure you have MetaMask!');
        return;
    } else {
        console.log('💲Wallet connected💲');
    }

    // Get network
    let chainId = await ethereum.request({ method: 'eth_chainId' });
    chainId = parseInt(chainId, 16).toString();

    // Get account, if one is authorized
    const accounts = await ethereum.request({ method: 'eth_accounts' });
    let account = accounts.length !== 0 ? accounts[0] : null;

    // Update state variables
    chainId = !!chainId ? chainId : null;
    account = !!account ? account : null;

    return { account, chainId };
}

export const connectWallet = async () => {
    /**
     * Connect ethereum wallet callback
     */
    try {
        const { ethereum } = window;

        if (!!ethereum) {
            const accounts = await ethereum.request({ method: 'eth_requestAccounts' });

            ethereum.on('accountsChanged', async (_) => {
                await checkIfWalletIsConnected();
            });
            return accounts[0];
        }

        alert('Get MetaMask => https://metamask.io/');
        return null;
    } catch (err) {
        console.error(err);
    }
}
