import '../../static/css/BorrowingPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import config from '../../config.json';

import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress } from '../../utils/addressUtils';
import { getNetworkName } from '../../utils/networkUtils';
import { checkIfWalletIsConnected as checkConnection, connectWallet } from '../../utils/window/ethereumConnect';

import { listenerLoanContractCreated } from '../../utils/events/listenersLoanContractFactory';
import { setAnzaDebtTokenMetadata, postAnzaDebtTokenIPFS } from '../../utils/adt/adtIPFS';
import { mintAnzaDebtToken } from '../../utils/adt/adtContract';

import { clientCreateTokensPortfolio as createTokensPortfolio } from '../../db/clientCreateTokensPortfolio';
import { clientUpdatePortfolioLeveragedStatus as updatePortfolioLeveragedStatus } from '../../db/clientUpdateTokensPortfolio';
import { clientReadBorrowerNotSignedJoin as readBorrowerNotSignedJoin } from '../../db/clientReadJoin';

import { createTokensLeveraged } from '../../db/clientCreateTokensLeveraged';
import { createTokensDebt } from '../../db/clientCreateTokensDebt';

import { Alchemy, Network } from "alchemy-sdk";

const _config = {
    apiKey: "dJvhY8kf7q1QuoBpxCoyZnmPamRmtlYH",
    network: Network.ETH_SEPOLIA,
};
const alchemy = new Alchemy(_config);

// import abi_ERC721 from '../../artifacts/IERC721.sol/IERC721.json'
// import abi_LoanContractFactory from '../../artifacts/contracts/social/LoanContractFactory.sol/LoanContractFactory.json';

export default function BorrowingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [newContract, setNewContract] = useState('');
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentAvailableNftsTable, setCurrentAvailableNftsTable] = useState(null);
    const [currentToken, setCurrentToken] = useState({ address: null, id: null });
    const [accountNfts, setAccountNfts] = useState({});

    useEffect(() => {
        console.log('Page loading...');
        if (!!isPageLoad) pageLoadSequence();
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
        const ownedNfts = await updateNftPortfolio(account);

        // Render table of potential NFTs
        const [availableNftsTable, token] = await renderNftTable(account, ownedNfts);

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

        await updatePortfolioLeveragedStatus(newContract, 'Y');

        // Render table of potential NFTs
        const [availableNftsTable, _] = await renderNftTable(currentAccount);
        setCurrentAvailableNftsTable(availableNftsTable);

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
        const { ethereum } = window;
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner(currentAccount);

        // // Set LoanContractFactory to operator
        // let LoanContractFactory = new ethers.Contract(
        //     config.LoanContractFactory,
        //     abi_LoanContractFactory.abi,
        //     signer
        // );

        // const tokenContract = new ethers.Contract(
        //     currentToken.address,
        //     abi_ERC721.abi,
        //     signer
        // );
        // let tx = await tokenContract.setApprovalForAll(LoanContractFactory.address, true);
        // await tx.wait();

        // // Get selected token terms
        // const principal = document.getElementsByClassName(`principal-${currentToken.address}-${currentToken.id}`)[0].value;
        // const fixedInterestRate = document.getElementsByClassName(`fixedInterestRate-${currentToken.address}-${currentToken.id}`)[0].value;
        // const duration = document.getElementsByClassName(`duration-${currentToken.address}-${currentToken.id}`)[0].value;
        // const adtSelectElement = document.getElementsByClassName(`adt-${currentToken.address}-${currentToken.id}`)[0];
        // const adtSelect = adtSelectElement.options[adtSelectElement.options.selectedIndex].text === 'Y';

        // // Set IPFS debt metadata object for AnzaDebtToken
        // const debtObj = await setAnzaDebtTokenMetadata(currentAccount);

        // // Create new LoanContract
        // tx = await LoanContractFactory.createLoanContract(
        //     config.LoanContract,
        //     currentToken.address,
        //     ethers.BigNumber.from(currentToken.id),
        //     ethers.utils.parseEther(principal),
        //     fixedInterestRate,
        //     duration
        // );
        // await tx.wait();

        // const [cloneAddress, tokenContractAddress, tokenId] = await listenerLoanContractCreated(tx, LoanContractFactory);

        // // Update databases
        // const primaryKey = `${tokenContractAddress}_${tokenId.toString()}`;

        // createTokensLeveraged(
        //     primaryKey,
        //     cloneAddress,
        //     currentAccount,
        //     tokenContractAddress,
        //     tokenId.toString(),
        //     ethers.constants.AddressZero,
        //     ethers.utils.parseEther(principal).toString(),
        //     fixedInterestRate,
        //     duration,
        //     'Y',
        //     'N'
        // );

        // if (adtSelect) {
        //     // Set IPFS LoanContract metadata object for AnzaDebtToken
        //     const loanContractObj = {
        //         loanContractAddress: cloneAddress,
        //         borrowerAddress: currentAccount,
        //         collateralTokenAddress: currentToken.address,
        //         collateralTokenId: currentToken.id,
        //         lenderAddress: ethers.constants.AddressZero,
        //         principal: principal,
        //         fixedInterestRate: fixedInterestRate,
        //         duration: duration
        //     }

        //     // Post AnzaDebtToken to IPFS
        //     let debtTokenAddress, debtTokenId, debtTokenURI;
        //     debtTokenURI = await postAnzaDebtTokenIPFS(debtObj, loanContractObj);

        //     // Mint AnzaDebtToken with IPFS URI
        //     [debtTokenAddress, debtTokenId, debtTokenURI] = await mintAnzaDebtToken(currentAccount, cloneAddress, debtTokenURI);
        //     console.log(debtTokenURI);

        //     createTokensDebt(
        //         primaryKey,
        //         debtTokenURI,
        //         debtTokenAddress,
        //         debtTokenId,
        //         principal
        //     );
        // }

        // setNewContract(primaryKey);
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
        setCurrentChainId(chainId);
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
    const updateNftPortfolio = async (account = currentAccount) => {
        if (!account) { return; }

        // Get tokens owned
        const { ownedNfts } = await alchemy.nft.getNftsForOwner(account, { includeFilters: "SPAM" });
        if (Object.keys(ownedNfts).length === 0) {
            console.log("No tokens owned.");
            return;
        }

        // Format tokens owned for database update
        const portfolioVals = [];
        Object.keys(ownedNfts).map((i) => {
            let primaryKey = `${ownedNfts[i].contract.address}_${ownedNfts[i].tokenId.toString()}`;

            portfolioVals.push([
                primaryKey,
                account,
                ownedNfts[i].contract.address,
                ownedNfts[i].tokenId,
            ]);
        });

        setAccountNfts(ownedNfts);

        return ownedNfts

        // // Update portfolio database
        // await createTokensPortfolio(portfolioVals);
    }

    /* ---------------------------------------  *
     *           FRONTEND RENDERING             *
     * ---------------------------------------  */
    const renderNftTable = async (account, ownedNfts) => {
        if (!account) { return [null, { address: null, id: null }]; }

        // Get non leveraged tokens
        // const tokens = await readBorrowerNotSignedJoin(account);
        // if (!tokens.length) { return [null, { address: null, id: null }]; }

        const termObj = {
            "principal": config.DEFAULT_TEST_VALUES.PRINCIPAL,
            "fixedInterestRate": config.DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE,
            "firInterval": config.firInterval,
            "gracePeriod": config.gracePeriod,
            "duration": config.duration,
            "commital": config.commital,
            "termsExpiry": config.termsExpiry,
            "lenderRoyalties": config.lenderRoyalties,
        }

        // Create token elements
        const tokenElements = [];
        tokenElements.push(
            Object.keys(ownedNfts).map((i) => {
                return (
                    <tr key={`tr-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}>
                        {/* RADIO BUTTON */}
                        <td key={`td-radio-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`} id={`id-radio-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}>
                            <input
                                type='radio'
                                key={`radio-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                name={`radio-${account}`}
                                value={`${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                defaultChecked={i === '0'}
                                onClick={callback__SetContractParams}
                            />
                        </td>
                        {/* COLLATERAL ADDRESS */}
                        <td key={`address-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`} id={`id-address-${i}`}>{getSubAddress(ownedNfts[i].contract.address)}</td>
                        {/* COLLATERAL ID */}
                        <td key={`tokenId-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`} id={`id-tokenId-${i}`}>{ownedNfts[i].tokenId}</td>
                        {/* IS DISABLED? */}
                        <select
                            key={`text-adt-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                            id={`terms-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                            name={`terms-${account}`}
                            className={`adt-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                            disabled={i !== '0'}
                        >
                            <option>N</option><option>Y</option>
                        </select>
                        {/* LENDING TERMS */}
                        {
                            Object.keys(termObj).map((term) => {
                                return (
                                    <td key={`td-${term}-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`} id={`id-text-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}>
                                        <input
                                            type='text'
                                            key={`text-${term}-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                            id={`terms-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                            name={`terms-${account}`}
                                            className={`loan-term-text ${term}-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                            defaultValue={termObj[term]}
                                            disabled={i !== '0'}
                                        />
                                    </td>
                                )
                            })
                        }
                        {/* MINT ANZA REPLICA TOKEN? */}
                        < td key={`td-adt-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`} id={`id-text-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`
                        }>
                            <select
                                key={`text-adt-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                id={`terms-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                name={`terms-${account}`}
                                className={`adt-${ownedNfts[i].contract.address}-${ownedNfts[i].tokenId}`}
                                disabled={i !== '0'}
                            >
                                <option>Y</option><option>N</option>
                            </select>
                        </td >
                    </tr >
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
                        <th><label>Direct Loan</label></th>
                        <th><label>Principal</label></th>
                        <th><label>Fixed Interest Rate (FIR)</label></th>
                        <th><label>FIR Interval</label></th>
                        <th><label>Grace Period (sec)</label></th>
                        <th><label>Duration (sec)</label></th>
                        <th><label>Commital (sec)</label></th>
                        <th><label>Terms Expiry (sec)</label></th>
                        <th><label>Lender Royalties</label></th>
                    </tr></thead>
                    <tbody>
                        {tokenElements}
                    </tbody>
                </table>
            </form>
        );

        console.log(ownedNfts[0])
        return [availableNftsTable, { address: ownedNfts[0].contract.address, id: ownedNfts[0].tokenId }];
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
