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
    checkIfWalletIsConnected as checkConnection,
    connectWallet
} from '../../utils/window/ethereumConnect';

import { 
    clientCreateTokensPortfolio as createTokensPortfolio
 } from '../../db/clientCreateTokensPortfolio';
 import {
    clientUpdatePortfolioLeveragedStatus as updatePortfolioLeveragedStatus
 } from '../../db/clientUpdateTokensPortfolio';

// import { clientReadNonLeveragedTokensPortfolio as readNonLeveragedTokensPortfolio } from '../../db/clientReadTokensPortfolio';
import { clientReadBorrowerNotSignedJoin as readBorrowerNotSignedJoin } from '../../db/clientReadJoin';
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
        // Update terms enable/disable
        const terms = document.getElementsByName(`terms-${currentAccount}`);
        [...terms].forEach((term) => { 
            term.disabled = `terms-${currentToken.address}-${currentToken.id}` != term.id;
        });
    }

    const newContractCreatedSequence = async () => {
        console.log('new contract created!');
        console.log(newContract);

        await updatePortfolioLeveragedStatus(newContract, 'Y');

        // Render table of potential NFTs
        const [availableNftsTable, _] = await renderNftTable(currentAccount);
        setCurrentAvailableNftsTable(availableNftsTable);
        console.log('currentAvailableNftsTable');
        console.log(availableNftsTable === currentAvailableNftsTable);

        window.location.reload();

        setNewContract('');
    }

    /* ---------------------------------------  *
     *           FRONTEND CALLBACKS             *
     * ---------------------------------------  */
    const callback__ConnectWallet = async () => {
        /**
         * Connect ethereum wallet callback
         */
        const account = await connectWallet();
        setCurrentAccount(account);
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

        // Get selected token terms
        const principal = document.getElementsByClassName(`principal-${currentToken.address}-${currentToken.id}`)[0].value;
        const fixedInterestRate = document.getElementsByClassName(`fixedInterestRate-${currentToken.address}-${currentToken.id}`)[0].value;
        const duration = document.getElementsByClassName(`duration-${currentToken.address}-${currentToken.id}`)[0].value;

        // Create new LoanContract via LoanContractFactory
        let tx = await LoanContractFactory.connect(signer).createLoanContract(
            config.LoanContract,
            config.LoanTreasurey,
            config.LoanCollection,
            currentToken.address,
            ethers.BigNumber.from(currentToken.id),
            ethers.utils.parseEther(principal),
            fixedInterestRate,
            duration
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
            ethers.utils.parseEther(principal).toString(),
            fixedInterestRate,
            duration,
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
        const { account, chainId } = await checkConnection();
        setCurrentChainId (chainId);
        setCurrentAccount(account);

        // set wallet event listeners
        const { ethereum } = window;
        ethereum.on('accountsChanged', () => window.location.reload());
        ethereum.on('chainChanged', () => window.location.reload());

        return { account, chainId };
    }

    /* ---------------------------------------  *
     *       DATABASE MODIFIER FUNCTIONS        *
     * ---------------------------------------  */
    const updateNftPortfolio = async (account=currentAccount) => {
        if (!account) { return; }

        // Get tokens owned
        const tokensOwned = config.DEMO_TOKENS[account];
        if (!tokensOwned) {
            console.log("No tokens owned.");
            return;
        }

        // Format tokens owned for database update
        const portfolioVals = [];
        Object.keys(tokensOwned).map((i) => {
            let primaryKey = `${tokensOwned[i].tokenContractAddress}_${tokensOwned[i].tokenId.toString()}`;

            portfolioVals.push([
                primaryKey,
                account,
                tokensOwned[i].tokenContractAddress,
                tokensOwned[i].tokenId.toString(),
            ]);
        });

        // Update portfolio database
        await createTokensPortfolio(portfolioVals);
    }

    /* ---------------------------------------  *
     *           FRONTEND RENDERING             *
     * ---------------------------------------  */
    const renderNftTable = async (account) => {
        if (!account) { return [null, { address: null, id: null}]; }

        // Get non leveraged tokens
        const tokens = await readBorrowerNotSignedJoin(account);
        if (!tokens.length) { return [null, { address: null, id: null}]; }

        // Create token elements
        const tokenElements = [];
        tokenElements.push(
            Object.keys(tokens).map((i) => {
                return (
                    <tr key={`tr-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}>
                        <td key={`td-radio-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-radio-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}><input
                            type='radio'
                            key={`radio-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            name={`radio-${tokens[i].ownerAddress}`}
                            value={`${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            defaultChecked={i==='0'}
                            onClick={callback__SetContractParams}
                        /></td>
                        <td key={`address-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-address-${i}`}>{getSubAddress(tokens[i].tokenContractAddress)}</td>
                        <td key={`tokenId-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}  id={`id-tokenId-${i}`}>{tokens[i].tokenId}</td>
                        <td key={`td-principal-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-text-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}><input
                            type='text'
                            key={`text-principal-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            id={`terms-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            name={`terms-${tokens[i].ownerAddress}`}
                            className={`principal-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            defaultValue={ethers.utils.formatEther(config.DEFAULT_TEST_VALUES.PRINCIPAL)}
                            disabled={i!=='0'}
                        /></td>
                        <td key={`td-fixedInterestRate-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-text-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}><input
                            type='text'
                            key={`text-fixedInterestRate-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            id={`terms-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            name={`terms-${tokens[i].ownerAddress}`}
                            className={`fixedInterestRate-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            defaultValue={config.DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE}
                            disabled={i!=='0'}
                        /></td>
                        <td key={`td-duration-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-text-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}><input
                            type='text'
                            key={`text-duration-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            id={`terms-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            name={`terms-${tokens[i].ownerAddress}`}
                            className={`duration-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
                            defaultValue={config.DEFAULT_TEST_VALUES.DURATION}
                            disabled={i!=='0'}
                        /></td>
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
                        <th><label>Principal (ETH)</label></th>
                        <th><label>APR</label></th>
                        <th><label>Duration (days)</label></th>
                    </tr></thead>
                    <tbody>
                        {tokenElements}
                    </tbody>
                </table>
            </form>
        );

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
                    <div className='button button-body' onClick={callback__CreateLoanContract}>Request Loan</div>
                </div>
                {currentAvailableNftsTable}
            </div>
        </main>
    );
}
