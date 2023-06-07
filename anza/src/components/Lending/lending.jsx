import '../../static/css/LoansPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import config from '../../config.json';

import { NftTable, setName } from '../Common/common';
import { listenerLoanContractInit } from '../../utils/events/listenersLoanContract';
import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress } from '../../utils/addressUtils';
import { getLendingTermsPrimaryKey } from '../../utils/databaseUtils';
import { getNetworkName } from '../../utils/networkUtils';
import { getOwnedTokens } from '../../utils/blockchainIndexingUtils';
import { loanStart, loanDuration } from '../../utils/constants/loanContractConstants';
import {
    checkIfWalletIsConnected as checkConnection,
    connectWallet
} from '../../utils/window/ethereumConnect';
import { selectAvailableLoanTerms, selectApprovedLoanTerms } from '../../db/client_selectLendingTerms';
import { selectSponsoredConfirmedLoans } from '../../db/client_selectConfirmedLoans';
import { insertConfirmedLoans } from '../../db/client_insertConfirmedLoans';
import {
    updateApprovedLendingTerms,
    updateUnallowedLendingTerms,
    updateRejectedLendingTerms
} from '../../db/client_updateLendingTerms';
import artifact_LoanContract from '../../artifacts/LoanContract.sol/LoanContract.json';
import artifact_LibLoanContractSigning from '../../artifacts/LibLoanContract.sol/LibLoanContractSigning.json';
import artifact_LibLoanContractTerms from '../../artifacts/LibLoanContract.sol/LibLoanContractTerms.json';

export default function LendingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentLoanProposalsTable, setCurrentLoanProposalsTable] = useState([null, null]);
    const [sponsoredConfirmedLoans, setSponsoredConfirmedLoansTable] = useState([null, null]);
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
        setPageTitle('Lending');

        // Set account and network
        const { account, chainId } = await checkIfWalletIsConnected();
        console.log(`Account: ${account}`);
        console.log(`Network: ${chainId}`);

        // Update nft.available table
        const ownedNfts = await getOwnedTokens(chainId, account);
        const sponsoredProposals = await selectSponsoredConfirmedLoans(account);
        const loanProposals = await getLoanProposals(ownedNfts, account)

        // Render table of sponsored loans
        const sponsoredLoans = await NftTable({
            account: account,
            nfts: sponsoredProposals,
            type: "confirmed",
            useDefaultTerms: false,
            disabledOverriden: true,
        });

        // Render table of potential NFTs
        const proposedLoans = await NftTable({
            account: account,
            nfts: loanProposals,
            type: "sponsor",
            useDefaultTerms: false,
            disabledOverriden: true,
        });

        proposedLoans[1] !== null && setCurrentToken({
            address: proposedLoans[1].address,
            id: proposedLoans[1].id
        });

        setSponsoredConfirmedLoansTable(sponsoredLoans);
        setCurrentLoanProposalsTable(proposedLoans);

        setIsPageLoad(false);
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
            const rowObj = { contract: { address: collateralAddress }, tokenId: collateralId, tableType: "sponsor", index: index };
            terms[type] = document.getElementsByName(setName(type, rowObj))[0].value;
            terms[type] = (type !== "principal") ? terms[type] : ethers.utils.parseEther(terms[type]).toString();
            terms[type] = (type !== "is_fixed") ? terms[type] : (terms[type] === "Y") ? 1 : 0;
        });

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

        // Get LibLoanContractTerms instance
        const LibLoanContractTerms = new ethers.Contract(
            config[currentChainId].LibLoanContractTerms,
            artifact_LibLoanContractTerms.abi,
            signer
        );

        // Get LibLoanContractSigning instance
        const LibLoanContractSigning = new ethers.Contract(
            config[currentChainId].LibLoanContractSigning,
            artifact_LibLoanContractSigning.abi,
            provider
        );

        // Store nonce for finding borrower later
        const collateralNonce = await LoanContract.getCollateralNonce(collateralAddress, collateralId);

        // Initialize loan contract
        let tx;
        try {
            tx = await LoanContract.connect(signer)[
                "initLoanContract(address,uint256,bytes32,bytes)"
            ](
                collateralAddress,
                collateralId,
                response["packed_contract_terms"],
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
        const _borrower = await LibLoanContractSigning.recoverSigner(
            response["principal"],
            response["packed_contract_terms"],
            _collateralAddress,
            _collateralId,
            collateralNonce,
            response["signed_message"]
        );

        const _lender = await signer.getAddress();
        const _loanTerms = await LoanContract.getDebtTerms(_debtId);

        const _loanStartTime = loanStart(_loanTerms.toString());
        const _loanCommitTime = await LibLoanContractTerms.loanCommitalTime(_loanTerms);
        const _loanCloseTime = _loanStartTime + loanDuration(_loanTerms.toString());

        // Set confirmed loan into database
        await setApprovedLoan(
            response["signed_message"],
            _debtId,
            getLendingTermsPrimaryKey(_collateralAddress, _collateralId),
            _borrower,
            _lender,
            _activeLoanIndex,
            _loanStartTime,
            _loanCommitTime,
            _loanCloseTime
        );
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
    const getLoanProposals = async (ownedNfts, account) => {
        const collateral = [];

        Object.keys(ownedNfts).map((i) => {
            collateral.push(
                getLendingTermsPrimaryKey(
                    ownedNfts[i].contract.address,
                    ownedNfts[i].tokenId
                )
            )
        });

        const data = await selectAvailableLoanTerms(collateral, account);

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
        loanCommitTime,
        loanCloseTime
    ) => {
        // Update confirmed loans with debt ID
        let response = await insertConfirmedLoans(
            debtId.toString(),
            borrower,
            lender,
            activeLoanIndex,
            loanStartTime,
            loanCommitTime,
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
        response = await updateUnallowedLendingTerms(collateral);
        response = await updateRejectedLendingTerms(collateral);

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
                {sponsoredConfirmedLoans[0]}
            </div>
            }
            <div className='container container-table container-table-available-nfts'>
                <h2>Available for Sponsor</h2>
                {!!currentLoanProposalsTable[1] && <div className='buttongroup buttongroup-body'>
                    <div className='button button-body' onClick={callback__SponsorLoanContract}>Sponsor Loan</div>
                </div>
                }
                {currentLoanProposalsTable[0]}
            </div>
        </main>
    );
}
