import '../../static/css/BorrowingPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import axios from 'axios';
import config from '../../config.json';

import { listenerLoanContractCreated } from '../../utils/events/listenersLoanContractFactory';

import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress } from '../../utils/addressUtils';
import { getNetworkName } from '../../utils/networkUtils';

import { 
    clientCreateTokensPortfolio as createTokensPortfolio
 } from '../../db/clientCreateTokensPortfolio';
 import {
    clientUpdatePortfolioLeveragedStatus as updatePortfolioLeveragedStatus
 } from '../../db/clientUpdateTokensPortfolio';

import { clientReadNonLeveragedTokensPortfolio as readNonLeveragedTokensPortfolio } from '../../db/clientReadTokensPortfolio';
import { createTokensLeveraged } from '../../db/clientCreateTokensLeveraged';

import abi_ERC721 from '../../artifacts/@openzeppelin/contracts/token/ERC721/ERC721.sol/ERC721.json';
import abi_LoanContractFactory from '../../artifacts/contracts/social/LoanContractFactory.sol/LoanContractFactory.json';

export default function BorrowingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [newContract, setNewContract] = useState('');
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentAvailableNftsTable, setCurrentAvailableNftsTable] = useState(null);
    const [currentToken, setCurrentToken] = useState({ address: null, id: null });

    useEffect(() => {
        console.log('Page loading...');
        if (!!isPageLoad) pageLoadSequence();
        // eslint-disable-next-line
    }, []);

    useEffect(() => {
        if (!!currentToken.address) tokenSelectionChangeSequence();
    }, [currentToken]);

    useEffect(() => {
        if (!!newContract) newContractCreatedSequence();
    }, [newContract])

    /* ---------------------------------------  *
     *       EVENT SEQUENCE FUNCTIONS           *
     * ---------------------------------------  */
    const pageLoadSequence = async () => {
        /**
         * Sequence when page is loaded.
         */

        // Set page title
        setPageTitle('Borrowing');

        // Set account and network
        const { account, chainId } = await checkIfWalletIsConnected();
        console.log(`Account: ${account}`);
        console.log(`Network: ${chainId}`);

        // Update nft.available table
        updateNftPortfolio(account);

        // Render table of potential NFTs
        const [availableNftsTable, token] = await renderNftTable(account);
        setCurrentToken({ address: token.address, id: token.id });
        setCurrentAvailableNftsTable(availableNftsTable);

        setIsPageLoad(false);
    }

    const tokenSelectionChangeSequence = async () => {
        // Update current selection
        // console.log(`Token change seq: ${currentToken.address}-${currentToken.id}`);
    }

    const newContractCreatedSequence = async () => {
        console.log('new contract created!');
        console.log(newContract);

        await updatePortfolioLeveragedStatus(newContract, 'Y');

        // Render table of potential NFTs
        const [availableNftsTable, _] = await renderNftTable(currentAccount);
        setCurrentAvailableNftsTable(availableNftsTable);
        console.log('currentAvailableNftsTable')
        console.log(availableNftsTable === currentAvailableNftsTable)

        setNewContract('');
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
            ethers.BigNumber.from(config.DEFAULT_TEST_VALUES.DURATION)
        );
        await tx.wait();

        const [clone, tokenContractAddress, tokenId] = await listenerLoanContractCreated(tx, LoanContractFactory);
        const primaryKey = `${tokenContractAddress}_${tokenId.toString()}`;

        createTokensLeveraged(
            primaryKey,
            clone, 
            currentAccount, 
            tokenContractAddress, 
            tokenId.toString(), 
            ethers.constants.AddressZero,
            config.DEFAULT_TEST_VALUES.PRINCIPAL,
            config.DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE,
            config.DEFAULT_TEST_VALUES.DURATION,
            'Y', 
            'N'
        );

        setNewContract(primaryKey);
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
     *       DATABASE MODIFIER FUNCTIONS        *
     * ---------------------------------------  */
    const updateNftPortfolio = async (account=currentAccount) => {
        if (!account) { return; }

        console.log(`http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/select/leveraged/${account}`)

        // Get tokens leveraged
        const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
        let endpoints = `/api/select/leveraged/all/${account}`;
        const tokensLeveraged = [];

        (await axios.get(`${domain}${endpoints}`)
            .then((response) => { return response.data; })
        ).map((obj) => {
                tokensLeveraged.push(obj.primaryKey);
        });

        endpoints = `/api/select/portfolio/${account}`;
        const portfolioVals = [];

        // Get tokens owned
        const tokensOwned = config.DEMO_TOKENS[account];
        Object.keys(tokensOwned).map((i) => {
            let primaryKey = `${tokensOwned[i].tokenContractAddress}_${tokensOwned[i].tokenId.toString()}`;
            let leveragedStatus = !tokensLeveraged.includes(primaryKey) ? 'N' : 'Y';

            portfolioVals.push([
                primaryKey,
                account,
                tokensOwned[i].tokenContractAddress,
                tokensOwned[i].tokenId.toString(),
                leveragedStatus
            ]);
        });

        await createTokensPortfolio(portfolioVals);
    }

    /* ---------------------------------------  *
     *           FRONTEND RENDERING             *
     * ---------------------------------------  */
    const renderNftTable = async (account) => {
        if (!account) { return [null, { address: null, id: null}]; }

        // const tokens = config.DEMO_TOKENS[account.toLowerCase()];
        const tokens = await readNonLeveragedTokensPortfolio(account);
        if (!tokens.length) { return [null, { address: null, id: null}]; }

        console.log('tokens');
        console.log(tokens);
        const tokenElements = [];
        
        tokenElements.push(
            Object.keys(tokens).map((i) => {
                return (
                    <tr key={`tr-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}>
                        <td key={`td-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-radio-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}><input
                            type="radio"
                            key={`radio-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            name={`${tokens[i].tokenContractAddress}`}
                            value={`${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            defaultChecked={i==='0'}
                            onClick={callback__SetContractParams}
                        /></td>
                        <td key={`address-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-address-${i}`}>{tokens[i].tokenContractAddress}</td>
                        <td key={`tokenId-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}  id={`id-tokenId-${i}`}>{tokens[i].tokenId}</td>
                    </tr>
                )
            })
        );
        
        const availableNftsTable = (    
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

        console.log('updating currentAvaialbleNftsTable')

        return [availableNftsTable, { address: tokens[0].tokenContractAddress, id: tokens[0].tokenId }];
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
                {currentAvailableNftsTable}
            </div>
        </main>
    );
}
