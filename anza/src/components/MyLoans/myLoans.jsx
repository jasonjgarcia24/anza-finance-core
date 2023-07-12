import '../../static/css/LoansPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import config from '../../config.json';

import { NftTable, setEnableControlId, setName } from '../Common/common';
import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress } from '../../utils/addressUtils';
import { getLendingTermsPrimaryKey } from '../../utils/databaseUtils';
import { getNetworkName } from '../../utils/networkUtils';
import { getSignedMessage, getContractTerms } from '../../utils/signingUtils';
import { getOwnedTokens, getChainTimeNow } from '../../utils/blockchainIndexingUtils';
import { checkIfWalletIsConnected as checkConnection, connectWallet } from '../../utils/window/ethereumConnect';
import { insertProposedLoanTerms } from '../../db/client_insertLendingTerms';
import { selectOpenConfirmedLoans, selectCommittedConfirmedLoans } from '../../db/client_selectConfirmedLoans';
import abi_LoanContract from '../../artifacts/LoanContract.sol/LoanContract.json';
import abi_ERC721 from '../../artifacts/IERC721.sol/IERC721.json';


export default function BorrowingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [newLoanProposal, setNewLoanProposal] = useState('');
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentOpenLoans, setCurrentOpenLoansTable] = useState([null, null]);
    const [currentCommitedLoans, setCurrentCommitedLoans] = useState([null, null]);
    const [currentToken, setCurrentToken] = useState({ address: null, id: null, debtId: null });

    useEffect(() => {
        console.log('Page loading...');
        if (!!isPageLoad) pageLoadSequence();
    }, []);

    useEffect(() => {
        if (!!currentToken.address) tokenSelectionChangeSequence();
    }, [currentToken]);

    useEffect(() => {
        // if (!!newLoanProposal) window.location.reload();
    }, [newLoanProposal]);

    /* ---------------------------------------  *
     *       EVENT SEQUENCE FUNCTIONS           *
     * ---------------------------------------  */
    const pageLoadSequence = async () => {
        // Set page title
        setPageTitle('My Loans');

        // Set account and network
        const { account, chainId } = await checkIfWalletIsConnected();
        console.log(`Account: ${account}`);
        console.log(`Network: ${chainId}`);

        // Update nft.savailable table
        const openLoans = await getOpenLoans(account)
        const committedLoans = await getCommittedLoans(account);

        console.log(openLoans);

        // Render table of open loans for refinancing
        const openLoansTable = await NftTable({
            account: account,
            nfts: openLoans,
            type: "open",
            useDefaultTerms: false,
            disabledOverriden: false,
            callbackRadioButton: callback__SetProposalParams,
            callbackSelect: callback__SetFixedLoanParams
        });

        // Render table of open loans for refinancing
        const committedLoansTable = await NftTable({
            account: account,
            nfts: committedLoans,
            type: "commit",
            useDefaultTerms: false,
            disabledOverriden: true,
        });

        console.log(`openLoansTable:`);
        console.log(openLoansTable[1]);

        openLoansTable[1].address !== null && setCurrentToken({
            address: openLoansTable[1].address.toLowerCase(),
            id: openLoansTable[1].id,
            debtId: openLoansTable[1].debtId
        });

        setCurrentOpenLoansTable(openLoansTable);
        setCurrentCommitedLoans(committedLoansTable);

        setIsPageLoad(false);
    }

    const tokenSelectionChangeSequence = async () => {
        // Update terms enable/disable
        const terms = document.getElementsByClassName("loan-term");
        const rowObj = {
            contract: { address: currentToken.address },
            tokenId: currentToken.id,
            tableType: "open"
        };

        [...terms].forEach((term) => {
            const [_term, , ,] = term.id.split('-');
            term.disabled = setEnableControlId(_term, rowObj) != term.id;
        });
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

    const callback__ProposeLoanTerms = async () => {
        const { ethereum } = window;
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner(currentAccount);

        // Set LoanContractFactory to operator
        const LoanContract = new ethers.Contract(
            config[currentChainId].LoanContract,
            abi_LoanContract.abi,
            signer
        );

        const TokenContract = new ethers.Contract(
            currentToken.address,
            abi_ERC721.abi,
            signer
        );

        // // Ensure LoanContract is an approver to move the NFT
        // let approver = await TokenContract.getApproved(currentToken.id);
        // if (approver.toLowerCase() !== LoanContract.address.toLowerCase()) {
        //     let tx = await TokenContract.approve(LoanContract.address, currentToken.id);
        //     await tx.wait();
        // }

        // Collect loan terms and signature for loan initialization
        const contractTerms = getContractTerms(currentToken.address, currentToken.id, 'open');

        const { packedContractTerms, collateralNonce, signedMessage } = await getSignedMessage(
            signer,
            currentChainId,
            contractTerms,
            currentToken.address,
            currentToken.id
        );

        console.log(`debt id: ${currentToken.debtId}`);

        // Insert loan proposal into database
        const response = await insertProposedLoanTerms(
            signedMessage,
            packedContractTerms,
            currentAccount,
            currentToken.address,
            currentToken.id,
            collateralNonce,
            contractTerms,
            currentToken.debtId
        );

        if (response.status === 200) {
            console.log("Loan proposal successfully saved to Anza database!");
        } else if (response.data.error.code === "ER_DUP_ENTRY") {
            console.error(`Duplicate loan proposal failure!\n${response.data.error.sql}`);
            return;
        } else {
            console.error(`Default loan proposal error.\n${response.data.error.sql}`);
            return;
        }

        // Update frontend
        setNewLoanProposal(signedMessage);
    }

    const callback__SetFixedLoanParams = async ({ target }) => {
        const isDisabled = target.value === "Y";

        const [, tokenAddress, tokenId, , index] = target.name.split('-');
        const rowObj = { contract: { address: tokenAddress }, tokenId: tokenId, tableType: "open", index: index };
        const firInterval = document.getElementsByName(setName("fir_interval", rowObj))[0];
        const gracePeriod = document.getElementsByName(setName("grace_period", rowObj))[0];
        const commital = document.getElementsByName(setName("commital", rowObj))[0];
        const lenderRoyalties = document.getElementsByName(setName("lender_royalties", rowObj))[0];

        firInterval.disabled = isDisabled;
        gracePeriod.disabled = isDisabled;
        commital.disabled = isDisabled;
        lenderRoyalties.disabled = isDisabled;

        if (isDisabled) {
            firInterval.value = config.FIXED_LOAN_VALUES.FIR_INTERVAL;
            gracePeriod.value = config.FIXED_LOAN_VALUES.GRACE_PERIOD;
            commital.value = config.FIXED_LOAN_VALUES.COMMITAL;
            lenderRoyalties.value = config.FIXED_LOAN_VALUES.LENDER_ROYALTIES;
        }
    }

    const callback__SetProposalParams = async ({ target }) => {
        const [tokenAddress, tokenId, , , debtId] = target.value.split('-');
        console.log("target value:");
        console.log(target.value);
        console.log(`Debt ID: ${debtId}`);

        if (currentToken.address === tokenAddress && currentToken.id === tokenId) {
            // Do nothing
            return;
        }

        setCurrentToken({ address: tokenAddress.toLowerCase(), id: tokenId, debtId: debtId });
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
     *           DATABASE FUNCTIONS             *
     * ---------------------------------------  */
    const getOpenLoans = async (account) => {
        const now = await getChainTimeNow()
        const data = await selectOpenConfirmedLoans(account, now);

        data.map((loan) => {
            loan.contract = {};
            [loan.contract.address, loan.tokenId] = loan.collateral.split("_");
            loan.debtId = loan.debt_id;
        });

        return data;
    }

    const getCommittedLoans = async (account) => {
        const now = await getChainTimeNow()
        const data = await selectCommittedConfirmedLoans(account, now);

        data.map((loan) => {
            loan.contract = {};
            [loan.contract.address, loan.tokenId] = loan.collateral.split("_");
        });

        return data;
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
                <h2>Open Loans</h2>
                {!!currentOpenLoans[0] !== null && <div className='buttongroup buttongroup-body'>
                    <div className='button button-body' onClick={callback__ProposeLoanTerms}>Refinance Loan</div>
                </div>
                }
                {currentOpenLoans[0]}
            </div>
            <div className='container container-table container-table-available-nfts'>
                <h2>Committed Loans</h2>
                {currentCommitedLoans[0]}
            </div>
        </main>
    );
}
