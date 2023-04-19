import '../../static/css/LoansPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import config from '../../config.json';

import { NftTable } from '../Common/common';
import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress } from '../../utils/addressUtils';
import { getLendingTermsPrimaryKey } from '../../utils/databaseUtils';
import { getNetworkName } from '../../utils/networkUtils';
import { getSignedMessage, getContractTerms } from '../../utils/signingUtils';
import { getOwnedTokens } from '../../utils/blockchainIndexingUtils';
import { checkIfWalletIsConnected as checkConnection, connectWallet } from '../../utils/window/ethereumConnect';
import { insertProposedLoanTerms } from '../../db/client_insertLendingTerms';
import { selectProposedLoanTerms } from '../../db/client_selectLendingTerms';
import abi_LoanContract from '../../artifacts/LoanContract.sol/LoanContract.json';
import abi_ERC721 from '../../artifacts/IERC721.sol/IERC721.json';


export default function BorrowingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [newLoanProposal, setNewLoanProposal] = useState('');
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentLoanProposalsTable, setCurrentLoanProposalsTable] = useState(null);
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
        if (!!newLoanProposal) window.location.reload();
    }, [newLoanProposal]);

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
        const ownedNfts = await updateNftPortfolio(account, chainId);
        const loanProposals = await getLoanProposals(ownedNfts)

        // Render table of potential NFTs
        const [proposedLoansTable, _] = await NftTable({
            account: account,
            nfts: loanProposals,
            type: "proposal",
            useDefaultTerms: false,
            disabledOverriden: true,
        });

        // Render table of owned NFTs
        const [availableNftsTable, token] = await NftTable({
            account: account,
            nfts: ownedNfts,
            type: "terms",
            useDefaultTerms: true,
            disabledOverriden: false,
            callbackRadioButton: callback__SetProposalParams,
            callbackSelect: callback__SetFixedLoanParams
        });

        token !== null && setCurrentToken({ address: token.address.toLowerCase(), id: token.id });
        setCurrentLoanProposalsTable(proposedLoansTable);
        setCurrentAvailableNftsTable(availableNftsTable);

        setIsPageLoad(false);
    }

    const tokenSelectionChangeSequence = async () => {
        // Update terms enable/disable
        const terms = document.getElementsByClassName("loan-term-text");


        [...terms].forEach((term) => {
            const [termType, , ,] = term.id.split('-');
            term.disabled = `${termType}-${currentToken.address}-${currentToken.id}-terms` != term.id;
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

        // Ensure LoanContract is an approver to move the NFT
        let approver = await TokenContract.getApproved(currentToken.id);
        if (approver.toLowerCase() !== LoanContract.address.toLowerCase()) {
            let tx = await TokenContract.approve(LoanContract.address, currentToken.id);
            await tx.wait();
        }

        // Collect loan terms and signature for loan initialization
        const contractTerms = getContractTerms(currentToken.address, currentToken.id);

        const { packedContractTerms, collateralNonce, signedMessage } = await getSignedMessage(
            signer,
            currentChainId,
            contractTerms,
            currentToken.address,
            currentToken.id
        );

        // Insert loan proposal into database
        const response = await insertProposedLoanTerms(
            signedMessage,
            packedContractTerms,
            currentToken.address,
            currentToken.id,
            collateralNonce,
            contractTerms
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

        const [, tokenAddress, tokenId] = target.id.split('-');

        const firInterval = document.getElementsByClassName(`firInterval-${tokenAddress}-${tokenId}`)[0];
        const gracePeriod = document.getElementsByClassName(`gracePeriod-${tokenAddress}-${tokenId}`)[0];
        const commital = document.getElementsByClassName(`commital-${tokenAddress}-${tokenId}`)[0];
        const lenderRoyalties = document.getElementsByClassName(`lenderRoyalties-${tokenAddress}-${tokenId}`)[0];

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
        const [tokenAddress, tokenId] = target.value.split('-');
        if (currentToken.address === tokenAddress && currentToken.id === tokenId) {
            // Do nothing
            return;
        }

        setCurrentToken({ address: tokenAddress.toLowerCase(), id: tokenId });
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
    const updateNftPortfolio = async (account = currentAccount, chainId = currentChainId) => {
        if (!account) { return; }

        const ownedNfts = await getOwnedTokens(chainId, account);

        // Format tokens owned for database update
        const portfolioVals = [];
        Object.keys(ownedNfts).map((i) => {
            let primaryKey = getLendingTermsPrimaryKey(
                ownedNfts[i].contract.address,
                ownedNfts[i].tokenId
            );

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

    const getLoanProposals = async (ownedNfts) => {
        const collateral = [];

        Object.keys(ownedNfts).map((i) => {
            collateral.push(
                getLendingTermsPrimaryKey(
                    ownedNfts[i].contract.address,
                    ownedNfts[i].tokenId
                )
            )
        });

        const data = await selectProposedLoanTerms(collateral);

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
            {!!currentLoanProposalsTable && <div className='container container-table container-table-available-nfts'>
                <h2>Loan Proposals</h2>
                {currentLoanProposalsTable}
            </div>
            }
            <div className='container container-table container-table-available-nfts'>
                <h2>Available Collateral</h2>
                <div className='buttongroup buttongroup-body'>
                    <div className='button button-body' onClick={callback__ProposeLoanTerms}>Propose Loan</div>
                </div>
                {currentAvailableNftsTable}
            </div>
        </main>
    );
}
