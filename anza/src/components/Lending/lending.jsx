// import '../../static/css/LendingPage.css';
// import '../../static/css/NftTable.css';
// import React, { useEffect, useState } from 'react';
// import { ethers } from 'ethers';

// import { listenerDeposited } from '../../utils/events/listenersAContractTreasurer';

// import { setPageTitle } from '../../utils/titleUtils';
// import { getSubAddress, getLinkedSubAddress, getSubCid } from '../../utils/addressUtils';
// import { getNetworkName } from '../../utils/networkUtils';
// import {
//     checkIfWalletIsConnected as checkConnection,
//     connectWallet
// } from '../../utils/window/ethereumConnect';

// import { 
//     clientCreateTokensPortfolio as createTokensPortfolio
//  } from '../../db/clientCreateTokensPortfolio';
//  import {
//     clientUpdatePortfolioLeveragedStatus as updatePortfolioLeveragedStatus
//  } from '../../db/clientUpdateTokensPortfolio';
//  import {
//     clientUpdateLeveragedLenderSigned as updateLeveragedLenderSigned
//  } from '../../db/clientUpdateTokensLeveraged';
//  import {
//     clientReadNonSponsoredTokensLeveragedContract as readNonSponsoredTokensLeveragedContract
//  } from '../../db/clientReadTokensLeveraged';

//  import {
//     clientReadNonSponsoredTokensJoin as readNonSponsoredTokensJoin
//  } from '../../db/clientReadJoin';

// import { clientReadLeveragedTokensPortfolio as readLeveragedTokensPortfolio } from '../../db/clientReadTokensPortfolio';
// import { updateTokensLeveraged } from '../../db/clientCreateTokensLeveraged';

// import abi_ERC721 from '../../artifacts/@openzeppelin/contracts/token/ERC721/ERC721.sol/ERC721.json';
// import abi_LoanContract from '../../artifacts/contracts/social/LoanContract.sol/LoanContract.json';

// export default function LendingPage() {
//     const [isPageLoad, setIsPageLoad] = useState(true);
//     const [newContract, setNewContract] = useState('');
//     const [currentAccount, setCurrentAccount] = useState(null);
//     const [currentChainId, setCurrentChainId] = useState(null);
//     const [currentLeveragedNftsTable, setCurrentLeveragedNftsTable] = useState(null);
//     const [currentToken, setCurrentToken] = useState({ address: null, id: null });

//     useEffect(() => {
//         console.log('Page loading...');
//         if (!!isPageLoad) pageLoadSequence();
//         // eslint-disable-next-line
//     }, []);

//     useEffect(() => {
//         if (!!currentToken.address) tokenSelectionChangeSequence();
//     }, [currentToken]);

//     useEffect(() => {
//         if (!!newContract) newContractSponsoredSequence();
//     }, [newContract])

//     /* ---------------------------------------  *
//      *       EVENT SEQUENCE FUNCTIONS           *
//      * ---------------------------------------  */
//     const pageLoadSequence = async () => {
//         /**
//          * Sequence when page is loaded.
//          */

//         // Set page title
//         setPageTitle('Lending');

//         // Set account and network
//         const { account, chainId } = await checkIfWalletIsConnected();
//         console.log(`Account: ${account}`);
//         console.log(`Network: ${chainId}`);

//         // Render table of potential NFTs
//         const [leveragedNftsTable, token] = await renderNftTable(account, chainId);
//         setCurrentToken({ address: token.address, id: token.id });
//         setCurrentLeveragedNftsTable(leveragedNftsTable);

//         setIsPageLoad(false);
//     }

//     const tokenSelectionChangeSequence = async () => {
//         // Update current selection
//         // console.log(`Token change seq: ${currentToken.address}-${currentToken.id}`);
//     }

//     const newContractSponsoredSequence = async () => {
//         console.log('new contract created!');

//         await updatePortfolioLeveragedStatus(newContract, 'Y');

//         // Render table of potential NFTs
//         const [leveragedNftsTable, _] = await renderNftTable(currentAccount);
//         setCurrentLeveragedNftsTable(leveragedNftsTable);

//         window.location.reload();

//         setNewContract('');
//     }

//     /* ---------------------------------------  *
//      *           FRONTEND CALLBACKS             *
//      * ---------------------------------------  */
//     const callback__ConnectWallet = async () => {
//         /**
//          * Connect ethereum wallet callback
//          */
//         const account = await connectWallet();
//         setCurrentAccount(account);
//     }

//     const callback__SponsorLoanContract = async () => {
//         // Get signer
//         const { ethereum } = window;
//         const provider = new ethers.providers.Web3Provider(ethereum);
//         const signer = provider.getSigner(currentAccount);

//         // const element = document.getElementsByName(`${currentAccount}-tokens`);
//         const { 
//             ownerAddress: loanContractAddress,
//             principal
//         } = await readNonSponsoredTokensLeveragedContract(currentToken.address, currentToken.id);

//         // Get contract
//         const LoanContract = new ethers.Contract(
//             loanContractAddress,
//             abi_LoanContract.abi,
//             provider
//         );

//         // Set lender
//         const tx = await LoanContract.connect(signer).setLender({ value: principal});
//         await tx.wait();

//         const [payee, weiAmount] = await listenerDeposited(tx, LoanContract);
//         console.log('SPONSORED!')

//         const primaryKey = `${currentToken.address}_${currentToken.id}`;
//         updateLeveragedLenderSigned(primaryKey, currentAccount, 'Y');

//         setNewContract(primaryKey);
//     }

//     const callback__SetContractParams = async ({ target }) => {
//         const [tokenAddress, tokenId] = target.value.split('-');
//         if (currentToken.address === tokenAddress && currentToken.id === tokenId) {
//             // Do nothing
//             return;
//         }

//         setCurrentToken({ address: tokenAddress, id: tokenId });
//     }
    
//     /* ---------------------------------------  *
//      *        PAGE MODIFIED FUNCTIONS           *
//      * ---------------------------------------  */
//     const checkIfWalletIsConnected = async () => {
//         /**
//          * Connect wallet state change function.
//          */
//         const { account, chainId } = await checkConnection();
//         setCurrentChainId (chainId);
//         setCurrentAccount(account);

//         // set wallet event listeners
//         const { ethereum } = window;
//         ethereum.on('accountsChanged', () => window.location.reload());
//         ethereum.on('chainChanged', () => window.location.reload());

//         return { account, chainId };
//     }

//     /* ---------------------------------------  *
//      *       DATABASE MODIFIER FUNCTIONS        *
//      * ---------------------------------------  */

//     /* ---------------------------------------  *
//      *           FRONTEND RENDERING             *
//      * ---------------------------------------  */
//     const renderNftTable = async (account, chainId) => {
//         if (!account) { return [null, { address: null, id: null}]; }

//         // const tokens = config.DEMO_TOKENS[account.toLowerCase()];
//         const tokens = await readNonSponsoredTokensJoin(account);
//         if (!tokens.length) { return [null, { address: null, id: null}]; }

//         const tokenElements = [];
        
//         tokenElements.push(
//             Object.keys(tokens).map((i) => {
//                 return (
//                     <tr key={`tr-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}>
//                         <td key={`td-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-radio-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}><input
//                             type="radio"
//                             key={`radio-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
//                             name={`${account}-tokens`}
//                             value={`${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}
//                             defaultChecked={i==='0'}
//                             onClick={callback__SetContractParams}
//                         /></td>
//                         <td key={`borrower-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-borrower-${i}`}>{getLinkedSubAddress(tokens[i].borrowerAddress, chainId)}</td>
//                         <td key={`address-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-address-${i}`}>{getLinkedSubAddress(tokens[i].tokenContractAddress, chainId)}</td>
//                         <td key={`tokenId-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`}  id={`id-tokenId-${i}`}>{tokens[i].tokenId}</td>
//                         <td key={`loanContract-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-loanContract-${i}`}>{getLinkedSubAddress(tokens[i].ownerAddress, chainId)}</td>
//                         <td key={`principal-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-principal-${i}`}>{`${ethers.utils.formatEther(tokens[i].principal)} ETH`}</td>
//                         <td key={`fixedInterestRate-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-fixedInterestRate-${i}`}>{tokens[i].fixedInterestRate}</td>
//                         <td key={`duration-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-duration-${i}`}>{tokens[i].duration}</td>
//                         <td key={`debtCid-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-debtCid-${i}`}><a href={tokens[i].cid} target="_blank">{tokens[i].cid && getSubCid(tokens[i].cid) || "-"}</a></td>
//                         <td key={`debtContract-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-debtContract-${i}`}>{tokens[i].cid && getLinkedSubAddress(tokens[i].debtTokenContractAddress, chainId) || "-"}</td>
//                         <td key={`debtTokenId-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-debtTokenId-${i}`}>{tokens[i].cid && tokens[i].debtTokenId || "-"}</td>
//                         <td key={`debtQuantity-${tokens[i].tokenContractAddress}-${tokens[i].tokenId}`} id={`id-debtQuantity-${i}`}>{tokens[i].cid && tokens[i].quantity + " ADT" || "-"}</td>
//                     </tr>
//                 )
//             })
//         );
        
//         const leveragedNftsTable = (    
//             <form className='form-table form-table-lending-nfts' name='form-table-lending-nfts'>
//                 <table className='table-lending-nfts'>
//                     <thead><tr>
//                         <th></th>
//                         <th><label>Borrower</label></th>
//                         <th><label>Token Contract</label></th>
//                         <th><label>Token ID</label></th>
//                         <th><label>Loan Contract</label></th>
//                         <th><label>Principal</label></th>
//                         <th><label>Interest Rate</label></th>
//                         <th><label>Duration</label></th>
//                         <th><label>Debt Ref</label></th>
//                         <th><label>Debt Contract</label></th>
//                         <th><label>Debt Token ID</label></th>
//                         <th><label>Debt Quantity</label></th>
//                     </tr></thead>
//                     <tbody>
//                         {tokenElements}
//                     </tbody>
//                 </table>
//             </form>
//         );

//         return [leveragedNftsTable, { address: tokens[0].tokenContractAddress, id: tokens[0].tokenId }];
//     }

//     /* ---------------------------------------  *
//      *         BORROWERPAGE.JSX RETURN           *
//      * ---------------------------------------  */
//     return (
//         <main style={{ padding: '1rem 0' }}>
//             <div className='buttongroup buttongroup-header'>
//                 <div className='button button-network'>{getNetworkName(currentChainId)}</div>
//             {!!currentAccount
//                 ? (<div className='button button-ethereum button-connected'>{getSubAddress(currentAccount)}</div>)
//                 : (<div className='button button-ethereum button-connect-wallet' onClick={callback__ConnectWallet}>Connect Wallet</div>)
//             }
//             </div>
//             <div className='container container-table container-table-available-nfts'>
//                 <h2>Available for Sponsor</h2>
//                 <div className='buttongroup buttongroup-body'>
//                     <div className='button button-body' onClick={callback__SponsorLoanContract}>Sponsor Loan</div>
//                 </div>
//                 {currentLeveragedNftsTable}
//             </div>
//         </main>
//     );
// }
