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
    clientReadSignedTokensLeveraged as readSignedTokensLeveraged
} from '../../db/clientReadTokensLeveraged';

import abi_ERC721 from '../../artifacts/@openzeppelin/contracts/token/ERC721/ERC721.sol/ERC721.json';
import abi_LoanContractFactory from '../../artifacts/contracts/social/LoanContractFactory.sol/LoanContractFactory.json';

export default function BorrowingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentLeveragedNftsTable, setCurrentLeveragedNftsTable] = useState(null);
    const [currentToken, setCurrentToken] = useState({ address: null, id: null });

    useEffect(() => {
        console.log('Page loading...');
        if (!!isPageLoad) pageLoadSequence();
        // eslint-disable-next-line
    }, []);

    /* ---------------------------------------  *
     *       EVENT SEQUENCE FUNCTIONS           *
     * ---------------------------------------  */
    const pageLoadSequence = async () => {
        /**
         * Sequence when page is loaded.
         */

        // Set page title
        setPageTitle('Sponsoring');

        // Set account and network
        const { account, chainId } = await checkIfWalletIsConnected();
        console.log(`Account: ${account}`);
        console.log(`Network: ${chainId}`);

        // Render table of sponsored loans
        const [leveragedNftsTable, token] = await renderNftTable(account);
        setCurrentToken({ address: token.address, id: token.id });
        setCurrentLeveragedNftsTable(leveragedNftsTable);


        setIsPageLoad(false);
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

    /* ---------------------------------------  *
     *           FRONTEND RENDERING             *
     * ---------------------------------------  */
    const renderNftTable = async (account) => {
        if (!account) { return [null, { address: null, id: null}]; }

        // const tokens = config.DEMO_TOKENS[account.toLowerCase()];
        const loanContracts = await readSignedTokensLeveraged(account);
        if (!loanContracts.length) { return; }// [null, { address: null, id: null}]; }

        const loanElements = [];
        
        loanElements.push(
            Object.keys(loanContracts).map((i) => {
                return (
                    <tr key={`tr-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}>
                        <td key={`address-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-address-${i}`}>{loanContracts[i].tokenContractAddress}</td>
                        <td key={`tokenId-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}  id={`id-tokenId-${i}`}>{loanContracts[i].tokenId}</td>
                        <td key={`loanContract-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-loanContract-${i}`}>{loanContracts[i].ownerAddress}</td>
                        <td key={`principal-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-principal-${i}`}>{`${ethers.utils.formatEther(loanContracts[i].principal)} ETH`}</td>
                        <td key={`fixedInterestRate-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-fixedInterestRate-${i}`}>{loanContracts[i].fixedInterestRate}</td>
                        <td key={`duration-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-duration-${i}`}>{loanContracts[i].duration}</td>
                    </tr>
                )
            })
        );
        
        const leveragedNftsTable = (    
            <form className='form-table form-table-lending-nfts' name='form-table-lending-nfts'>
                <table className='table-lending-nfts'>
                    <thead><tr>
                        <th><label>Token Contract</label></th>
                        <th><label>Token ID</label></th>
                        <th><label>Loan Contract</label></th>
                        <th><label>Principal</label></th>
                        <th><label>Interest Rate</label></th>
                        <th><label>Duration</label></th>
                    </tr></thead>
                    <tbody>
                        {loanElements}
                    </tbody>
                </table>
            </form>
        );

        return [leveragedNftsTable, { address: loanContracts[0].tokenContractAddress, id: loanContracts[0].tokenId }];
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
                <h2>Sponsored Loans</h2>
                <h3>Open</h3>
                {currentLeveragedNftsTable}
            </div>
        </main>
    );
}
