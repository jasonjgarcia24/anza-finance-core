import '../../static/css/BorrowingPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import axios from 'axios';
import config from '../../config.json';

import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress, getLinkedSubAddress } from '../../utils/addressUtils';
import { getNetworkName } from '../../utils/networkUtils';


export default function BorrowingPage() {
    // const [isPageLoad, setIsPageLoad] = useState(true);
    // const [currentAccount, setCurrentAccount] = useState(null);
    // const [currentChainId, setCurrentChainId] = useState(null);
    // const [currentLeveragedNftsTable, setCurrentLeveragedNftsTable] = useState(null);
    // const [currentToken, setCurrentToken] = useState({ address: null, id: null });

    // useEffect(() => {
    //     console.log('Page loading...');
    //     if (!!isPageLoad) pageLoadSequence();
    //     // eslint-disable-next-line
    // }, []);

    // /* ---------------------------------------  *
    //  *       EVENT SEQUENCE FUNCTIONS           *
    //  * ---------------------------------------  */
    // const pageLoadSequence = async () => {
    //     /**
    //      * Sequence when page is loaded.
    //      */

    //     // Set page title
    //     setPageTitle('Loan Contracts');

    //     // Set account and network
    //     const { account, chainId } = await checkIfWalletIsConnected();
    //     console.log(`Account: ${account}`);
    //     console.log(`Network: ${chainId}`);

    //     // Render table of sponsored loans
    //     const [leveragedNftsTable, token] = await renderNftTable(account, chainId);
    //     setCurrentToken({ address: token.address, id: token.id });
    //     setCurrentLeveragedNftsTable(leveragedNftsTable);


    //     setIsPageLoad(false);
    // }

    // /* ---------------------------------------  *
    //  *           FRONTEND CALLBACKS             *
    //  * ---------------------------------------  */
    // const callback__ConnectWallet = async () => {
    //     /**
    //      * Connect ethereum wallet callback
    //      */
    //     try {
    //         const { ethereum } = window;

    //         if (!!ethereum) {
    //             const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    //             setCurrentAccount(accounts[0]);

    //             ethereum.on('accountsChanged', async (_) => {
    //                 await checkIfWalletIsConnected();
    //             });
    //             return;
    //         }

    //         alert('Get MetaMask => https://metamask.io/');
    //         return;
    //     } catch (err) {
    //         console.error(err);
    //     }
    // }

    // const callback__SubmitPayment = async (loanContractAddress) => {
    //     console.log(loanContractAddress);
    // }

    // /* ---------------------------------------  *
    //  *        PAGE MODIFIED FUNCTIONS           *
    //  * ---------------------------------------  */
    // const checkIfWalletIsConnected = async () => {
    //     /**
    //      * Connect wallet state change function.
    //      */

    //     // Get wallet's ethereum object
    //     const { ethereum } = window;

    //     if (!ethereum) {
    //         console.log('Make sure you have MetaMask!');
    //         return;
    //     } else {
    //         console.log('Wallet connected :)');
    //     }

    //     // Get network
    //     let chainId = await ethereum.request({ method: 'eth_chainId' });
    //     chainId = parseInt(chainId, 16).toString();

    //     // Get account, if one is authorized
    //     const accounts = await ethereum.request({ method: 'eth_accounts' });
    //     let account = accounts.length !== 0 ? accounts[0] : null;

    //     // Update state variables
    //     chainId = !!chainId ? chainId : null;
    //     account = !!account ? account : null;
    //     setCurrentChainId(chainId);
    //     setCurrentAccount(account);

    //     // set wallet event listeners
    //     ethereum.on('accountsChanged', () => window.location.reload());
    //     ethereum.on('chainChanged', () => window.location.reload());

    //     return { account, chainId };
    // }

    // /* ---------------------------------------  *
    //  *       DATABASE MODIFIER FUNCTIONS        *
    //  * ---------------------------------------  */

    // /* ---------------------------------------  *
    //  *           FRONTEND RENDERING             *
    //  * ---------------------------------------  */
    // const renderNftTable = async (account, chainId) => {
    //     if (!account) { return [null, { address: null, id: null }]; }

    //     const loanContracts = await readBorrowerSignedTokensLeveraged(account);
    //     if (!loanContracts.length) { return; }

    //     const { ethereum } = window;
    //     const provider = new ethers.providers.Web3Provider(ethereum);
    //     const signer = provider.getSigner(account);
    //     const loanElements = [];

    //     loanElements.push(
    //         await Promise.all(
    //             Object.keys(loanContracts).map(async (i) => {
    //                 const LoanContract = new ethers.Contract(
    //                     loanContracts[i].ownerAddress,
    //                     abi_LoanContract.abi,
    //                     signer
    //                 );

    //                 const loanContractBalance = await LoanContract.getBalance();

    //                 return (
    //                     <tr key={`tr-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}>
    //                         <td key={`borrower-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-borrower-${i}`}>{getLinkedSubAddress(loanContracts[i].borrowerAddress, chainId)}</td>
    //                         <td key={`lender-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-lender-${i}`}>{getLinkedSubAddress(loanContracts[i].lenderAddress, chainId)}</td>
    //                         <td key={`address-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-address-${i}`}>{getLinkedSubAddress(loanContracts[i].tokenContractAddress, chainId)}</td>
    //                         <td key={`tokenId-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-tokenId-${i}`}>{loanContracts[i].tokenId}</td>
    //                         <td key={`loanContract-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-loanContract-${i}`}>{getLinkedSubAddress(loanContracts[i].ownerAddress, chainId)}</td>
    //                         <td key={`principal-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-principal-${i}`}>{`${ethers.utils.formatEther(loanContracts[i].principal)} ETH`}</td>
    //                         <td key={`fixedInterestRate-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-fixedInterestRate-${i}`}>{loanContracts[i].fixedInterestRate}</td>
    //                         <td key={`duration-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-duration-${i}`}>{loanContracts[i].duration}</td>
    //                         <td key={`balance-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-balance-${i}`}>{`${ethers.utils.formatEther(loanContractBalance)} ETH`}</td>
    //                         <td key={`td-payment-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`} id={`id-text-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}><input
    //                             type='text'
    //                             key={`text-payment-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}
    //                             id={`pay-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}
    //                             name={`pay-${loanContracts[i].ownerAddress}`}
    //                             className={`payment-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}
    //                         /></td>
    //                         <td><div
    //                             key={`button-payment-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}
    //                             id={`payment-${loanContracts[i].tokenContractAddress}-${loanContracts[i].tokenId}`}
    //                             name={`payment-${loanContracts[i].ownerAddress}`}
    //                             className='button button-ethereum button-connected'
    //                             onClick={() => callback__SubmitPayment(loanContracts[i].ownerAddress)}
    //                         >Pay
    //                         </div></td>
    //                     </tr>
    //                 );
    //             })
    //         )
    //     );

    //     const leveragedNftsTable = (
    //         <form className='form-table form-table-lending-nfts' name='form-table-lending-nfts'>
    //             <table className='table-lending-nfts'>
    //                 <thead><tr>
    //                     <th><label>Borrower</label></th>
    //                     <th><label>Lender</label></th>
    //                     <th><label>Token Contract</label></th>
    //                     <th><label>Token ID</label></th>
    //                     <th><label>Loan Contract</label></th>
    //                     <th><label>Principal</label></th>
    //                     <th><label>Interest Rate</label></th>
    //                     <th><label>Duration</label></th>
    //                     <th><label>Balance</label></th>
    //                     <th><label>Payment (ETH)</label></th>
    //                 </tr></thead>
    //                 <tbody>
    //                     {loanElements}
    //                 </tbody>
    //             </table>
    //         </form>
    //     );

    //     return [leveragedNftsTable, { address: loanContracts[0].tokenContractAddress, id: loanContracts[0].tokenId }];
    // }

    // /* ---------------------------------------  *
    //  *         BORROWERPAGE.JSX RETURN           *
    //  * ---------------------------------------  */
    // return (
    //     <main style={{ padding: '1rem 0' }}>
    //         <div className='buttongroup buttongroup-header'>
    //             <div className='button button-network'>{getNetworkName(currentChainId)}</div>
    //             {!!currentAccount
    //                 ? (<div className='button button-ethereum button-connected'>{getSubAddress(currentAccount)}</div>)
    //                 : (<div className='button button-ethereum button-connect-wallet' onClick={callback__ConnectWallet}>Connect Wallet</div>)
    //             }
    //         </div>
    //         <div className='container container-table container-table-available-nfts'>
    //             <h2>Active Loans</h2>
    //             {currentLeveragedNftsTable}
    //         </div>
    //     </main>
    // );
}
