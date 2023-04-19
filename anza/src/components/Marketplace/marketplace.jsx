import '../../static/css/LoansPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import config from '../../config.json';

import { NftTable } from '../Common/common';
import { listenerLoanContractInit } from '../../utils/events/listenersLoanContract';
import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress } from '../../utils/addressUtils';
import { getLendingTermsPrimaryKey } from '../../utils/databaseUtils';
import { getNetworkName } from '../../utils/networkUtils';
import { getOwnedTokens } from '../../utils/blockchainIndexingUtils';
import {
    checkIfWalletIsConnected as checkConnection,
    connectWallet
} from '../../utils/window/ethereumConnect';
import { selectAvailableLoanTerms, selectApprovedLoanTerms } from '../../db/client_selectLendingTerms';
import { selectConfirmedLoans } from '../../db/client_selectConfirmedLoans';
import { insertConfirmedLoans } from '../../db/client_insertConfirmedLoans';
import {
    updateApprovedLendingTerms,
    updateUnallowedCollateralLendingTerms
} from '../../db/client_updateLendingTerms';
import artifact_LoanContract from '../../artifacts/LoanContract.sol/LoanContract.json';
import artifact_LibLoanContractSigning from '../../artifacts/LibLoanContract.sol/LibLoanContractSigning.json';

export default function LendingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [newSponsoredLoan, setNewSponsoredLoan] = useState('');
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentLoanProposalsTable, setCurrentLoanProposalsTable] = useState(null);
    const [sponsoredConfirmedLoans, setSponsoredConfirmedLoansTable] = useState(null);
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
        if (!!newSponsoredLoan) window.location.reload();
    }, [newSponsoredLoan])

    /* ---------------------------------------  *
     *       EVENT SEQUENCE FUNCTIONS           *
     * ---------------------------------------  */
    const pageLoadSequence = async () => {
        /**
         * Sequence when page is loaded.
         */

        // Set page title
        setPageTitle('Debt Marketplace');

        // Set account and network
        const { account, chainId } = await checkIfWalletIsConnected();
        console.log(`Account: ${account}`);
        console.log(`Network: ${chainId}`);

        // Update nft.available table
        const ownedNfts = await getOwnedTokens(chainId, account);
        const loanProposals = await getLoanProposals(ownedNfts)
        const confirmedLoans = await selectConfirmedLoans();

        // Render table of sponsored loans
        const [sponsoredLoansTable, _] = await NftTable({
            account: account,
            nfts: confirmedLoans,
            type: "sponsor",
            useDefaultTerms: false,
            disabledOverriden: true,
        });

        // Render table of potential NFTs
        const [proposedLoansTable, token] = await NftTable({
            account: account,
            nfts: loanProposals,
            type: "sponsor",
            useDefaultTerms: false,
            disabledOverriden: true,
        });

        token !== null && setCurrentToken({ address: token.address, id: token.id });
        sponsoredLoansTable !== null && setSponsoredConfirmedLoansTable(sponsoredLoansTable);
        proposedLoansTable !== null && setCurrentLoanProposalsTable(proposedLoansTable);

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
        const account = await connectWallet();
        setCurrentAccount(account);
    }

    const callback__SponsorLoanContract = async () => {
        const { ethereum } = window;
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner(currentAccount);

        // Get approved terms
        const elements = document.getElementsByClassName(`radio-sponsor`);
        const selectedProposal = Object.values(elements).filter((element) => element.checked)[0].value;

        let terms = {
            "is_fixed": undefined,
            "principal": undefined,
            "fixed_interest_rate": undefined,
            "fir_interval": undefined,
            "grace_period": undefined,
            "duration": undefined,
            "commital": undefined,
            "terms_expiry": undefined,
            "lender_royalties": undefined
        };

        const [collateralAddress, collateralId, , index] = selectedProposal.split("-");

        Object.keys(terms).map((type) => {
            terms[type] = document.getElementsByName(`${type}-${collateralAddress}-${collateralId}-${index}`)[0].value;
            terms[type] = (type !== "principal") ? terms[type] : ethers.utils.parseEther(terms[type]).toString();
            terms[type] = (type !== "is_fixed") ? terms[type] : (terms[type] === "Y") ? 1 : 0;
        });
        console.log(terms)

        terms["collateral"] = getLendingTermsPrimaryKey(collateralAddress, collateralId);

        // Get selected approved loan terms
        let response = (await selectApprovedLoanTerms(
            terms["collateral"],
            terms["is_fixed"],
            terms["principal"],
            terms["fixed_interest_rate"],
            terms["fir_interval"],
            terms["grace_period"],
            terms["duration"],
            terms["commital"],
            terms["terms_expiry"],
            terms["lender_royalties"]
        ))[0];

        // Get LoanContract instance
        const LoanContract = new ethers.Contract(
            config[currentChainId].LoanContract,
            artifact_LoanContract.abi,
            signer
        );

        // Store nonce for finding borrower later
        const collateralNonce = await LoanContract.getCollateralNonce(collateralAddress, collateralId);

        // Initialize loan contract
        let tx;
        try {
            tx = await LoanContract.connect(signer)[
                "initLoanContract(bytes32,address,uint256,bytes)"
            ](
                response["packed_contract_terms"],
                collateralAddress,
                collateralId,
                response["signed_message"],
                { value: response["principal"], gasLimit: 1000000 }
            );
        } catch (err) {
            console.error(err.message);
            return;
        }

        // Capture LoanContractInit event
        const [
            _collateralAddress,
            _collateralId,
            _debtId,
            _activeLoanIndex
        ] = await listenerLoanContractInit(tx, LoanContract);

        // Get borrower
        const LibLoanContractSigning = new ethers.Contract(
            config[currentChainId].LibLoanContractSigning,
            artifact_LibLoanContractSigning.abi,
            provider
        );

        const _borrower = await LibLoanContractSigning.recoverSigner(
            response["principal"],
            response["packed_contract_terms"],
            _collateralAddress,
            _collateralId,
            collateralNonce,
            response["signed_message"]
        );
        const _lender = await signer.getAddress();
        const _loanStartTime = await LoanContract.loanStart(_debtId);
        const _loanCloseTime = await LoanContract.loanClose(_debtId);

        // Set confirmed loan into database
        await setApprovedLoan(
            response["signed_message"],
            _debtId,
            getLendingTermsPrimaryKey(_collateralAddress, _collateralId),
            _borrower,
            _lender,
            _activeLoanIndex,
            _loanStartTime,
            _loanCloseTime
        );

        setNewSponsoredLoan(_debtId);
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

        const data = await selectAvailableLoanTerms(collateral);

        return data;
    }

    const setApprovedLoan = async (
        signedMessage,
        debtId,
        collateral,
        borrower,
        lender,
        activeLoanIndex,
        loanStartTime,
        loanCloseTime
    ) => {
        // Update confirmed loans with debt ID
        let response = await insertConfirmedLoans(
            debtId.toString(),
            borrower,
            lender,
            activeLoanIndex,
            loanStartTime,
            loanCloseTime
        );

        if (response.status === 200) {
            console.log("Confirmed loans successfully updated at Anza database!");
            await pageLoadSequence();
        } else {
            console.error(`Default confirmed loans error.\n${response.data.error.sql}`);
        }

        // Update loan proposal database with debt ID
        response = await updateApprovedLendingTerms(signedMessage, debtId);

        if (response.status === 200) {
            console.log("Loan proposal successfully updated at Anza database!");
            await pageLoadSequence();
        } else {
            console.error(`Default loan proposal error.\n${response.data.error.sql}`);
        }

        // Clean-up all loans proposals with same collateral
        response = await updateUnallowedCollateralLendingTerms(collateral);

        if (response.status === 200) {
            console.log("Loan proposals successfully updated at Anza database!");
            await pageLoadSequence();
        } else {
            console.error(`Default loan proposal error.\n${response.data.error.sql}`);
        }
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
            {!!sponsoredConfirmedLoans && <div className='container container-table container-table-sponsored-loans'>
                <h2>Sponsored Loans</h2>
                {sponsoredConfirmedLoans}
            </div>
            }
            <div className='container container-table container-table-available-nfts'>
                <h2>Available for Sponsor</h2>
                <div className='buttongroup buttongroup-body'>
                    <div className='button button-body' onClick={callback__SponsorLoanContract}>Sponsor Loan</div>
                </div>
                {currentLoanProposalsTable}
            </div>
        </main>
    );
}
