import '../../static/css/BorrowingPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import { create } from 'ipfs-http-client';

import { listenerLoanContractCreated } from '../../utils/events/listenersLoanContractFactory';
import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress } from '../../utils/addressUtils';
import { getNetworkName } from '../../utils/networkUtils';
import { insertContracts } from '../../db/insert_contracts';
import config from '../../config.json';

import abi_ERC721 from '../../artifacts/@openzeppelin/contracts/token/ERC721/ERC721.sol/ERC721.json';
import abi_LoanContractFactory from '../../artifacts/contracts/social/LoanContractFactory.sol/LoanContractFactory.json';
import axios from 'axios';

export default function BorrowingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [contracts, setContracts] = useState(null);
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentAvailableNfts, setCurrentAvailableNfts] = useState(null);
    const [currentToken, setCurrentToken] = useState({ address: null, id: null });

    useEffect(() => {
        console.log('Page loading...');
        if (!!isPageLoad) pageLoadSequence();
        // eslint-disable-next-line
    }, []);

    useEffect(() => {
        if (!!currentToken.address) tokenSelectionChangeSequence();
    }, [currentToken]);

    /* ---------------------------------------  *
     *       EVENT SEQUENCE FUNCTIONS           *
     * ---------------------------------------  */
    const pageLoadSequence = async () => {
        /**
         * Sequence when page is loaded.
         */

        // Set page title
        setPageTitle('Lending');

        // Set account and network
        const { account, chainId } = await checkIfWalletIsConnected();
        console.log(`Account: ${account}`);
        console.log(`Network: ${chainId}`);

        // Render table of potential NFTs
        const token = await renderNftTable(account);
        setCurrentToken(token);

        setIsPageLoad(false);
    }

    const tokenSelectionChangeSequence = async () => {
        // Update current selection
        // console.log(`Token change seq: ${currentToken.address}-${currentToken.id}`);
    }

    /* ---------------------------------------  *
     *           FRONTEND CALLBACKS             *
     * ---------------------------------------  */
    const callback__ConnectWallet = async () => {
        /**
         * Connect ethereum wallet callback
         */
        try {
            const { ethereum } = window;

            if (!!ethereum) {
                const accounts = await ethereum.request({ method: 'eth_requestAccounts'});
                setCurrentAccount(accounts[0]);

                ethereum.on('accountsChanged', async (_) => {
                    await checkIfWalletIsConnected();
                });
                return;
            }

            alert('Get MetaMask => https://metamask.io/');
            return;
        } catch (err) {
            console.error(err);
        }
    }

    const callback__CreateLoanContract = async () => {
        // Get signer
        const { ethereum } = window;
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner(currentAccount);

        // Get contract
        let LoanContractFactory = new ethers.Contract(
            config.LoanContractFactory,
            abi_LoanContractFactory.abi,
            provider
        );

        // Set LoanContractFactory to operator
        const tokenContract = new ethers.Contract(currentToken.address, abi_ERC721.abi, signer);
        await tokenContract.setApprovalForAll(LoanContractFactory.address, true);

        // Create new LoanContract via LoanContractFactory
        let tx = await LoanContractFactory.connect(signer).createLoanContract(
            config.LoanContract,
            config.LoanTreasurey,
            config.LoanCollection,
            currentToken.address,
            ethers.BigNumber.from(currentToken.id),
            ethers.BigNumber.from(config.DEFAULT_TEST_VALUES.PRINCIPAL),
            ethers.BigNumber.from(config.DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE),
            ethers.BigNumber.from(parseInt(config.DEFAULT_TEST_VALUES.DURATION))
        );
        await tx.wait();

        const [clone, tokenContractAddress, tokenId] = await listenerLoanContractCreated(tx, LoanContractFactory);
        await insertContracts(currentAccount, tokenContractAddress, tokenId.toNumber(), clone);

        console.log(` --- account: ${currentAccount}`)
        axios.get(
            `http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/select/${currentAccount}`
        ).then((response) => { console.log(response.data); });
    }

    const callback__SetContractParams = async ({ target }) => {
        const [tokenAddress, tokenId] = target.value.split('-');
        if (currentToken.address === tokenAddress && currentToken.id === tokenId) {
            // Do nothing
            return;
        }

        setCurrentToken({ address: tokenAddress, id: tokenId });
    }
    
    /* ---------------------------------------  *
     *        PAGE MODIFIED FUNCTIONS           *
     * ---------------------------------------  */
    const checkIfWalletIsConnected = async () => {
        /**
         * Connect wallet state change function.
         */

        // Get wallet's ethereum object
        const { ethereum } = window;

        if (!ethereum) {
            console.log('Make sure you have MetaMask!');
            return;
        } else {
            console.log('Wallet connected :)');
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
        setCurrentChainId (chainId);
        setCurrentAccount(account);

        // set wallet event listeners
        ethereum.on('accountsChanged', () => window.location.reload());
        ethereum.on('chainChanged', () => window.location.reload());

        return { account, chainId };
    }

    /* ---------------------------------------  *
     *           FRONTEND RENDERING             *
     * ---------------------------------------  */
    const renderNftTable = async (account) => {
        if (!isPageLoad) { return; }

        const tokens = config.DEMO_TOKENS[account.toLowerCase()].tokens;
        const tokenElements = [];
        
        tokenElements.push(
            tokens.tokenId.map((tokenId, i) => {
                return (
                    <tr key={`tr-${tokens.address}-${tokenId}`}>
                        <td key={`td-${tokens.address}-${tokenId}`} id={`id-radio-${tokens.address}-${tokenId}`}><input
                            type="radio"
                            key={`radio-${tokens.address}-${tokenId}`}
                            name={`${tokens.address}`}
                            value={`${tokens.address}-${tokenId}`}
                            defaultChecked={i===0}
                            onClick={callback__SetContractParams}
                        /></td>
                        <td key={`address-${tokens.address}-${tokenId}`} id={`id-address-${i}`}>{tokens.address}</td>
                        <td key={`tokenId-${tokens.address}-${tokenId}`}  id={`id-tokenId-${i}`}>{tokenId}</td>
                    </tr>
                )
            })
        );
        
        setCurrentAvailableNfts(    
            <form className='form-table form-table-available-nfts'>
                <table className='table-available-nfts'>
                    <thead><tr>
                        <th></th>
                        <th><label>Contract</label></th>
                        <th><label>Token ID</label></th>
                    </tr></thead>
                    <tbody>
                        {tokenElements}
                    </tbody>
                </table>
            </form>
        );

        return { address: tokens.address, id: tokens.tokenId[0]};
    }

    /* ---------------------------------------  *
     *         BORROWERPAGE.JSX RETURN           *
     * ---------------------------------------  */
    return (
        <main style={{ padding: '1rem 0' }}>
            <div className='buttongroup buttongroup-header'>
                <div className='button button-network'>{getNetworkName(currentChainId)}</div>
            {!!currentAccount
                ? (<div className='button button-ethereum button-connected'>{getSubAddress(currentAccount)}</div>)
                : (<div className='button button-ethereum button-connect-wallet' onClick={callback__ConnectWallet}>Connect Wallet</div>)
            }
            </div>
            <div className='container container-table container-table-available-nfts'>
                <h2>Available Collateral</h2>
                <div className='buttongroup buttongroup-body'>
                    <div className='button button-body' onClick={callback__CreateLoanContract}>Submit Loan</div>
                </div>
                {currentAvailableNfts}
            </div>
        </main>
    );
}