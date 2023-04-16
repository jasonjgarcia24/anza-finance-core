import '../../static/css/LendingPage.css';
import '../../static/css/NftTable.css';
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import config from '../../config.json';

import { NftTable } from '../Common/common';

import { listenerDeposited } from '../../utils/events/listenersAContractTreasurer';
import { listenerLoanContractInit } from '../../utils/events/listenersLoanContractFactory';

import { setPageTitle } from '../../utils/titleUtils';
import { getSubAddress, getLinkedSubAddress, getSubCid } from '../../utils/addressUtils';
import { getNetworkName } from '../../utils/networkUtils';
import { getOwnedTokens } from '../../utils/blockchainIndexingUtils';
import {
    checkIfWalletIsConnected as checkConnection,
    connectWallet
} from '../../utils/window/ethereumConnect';

import { selectAvailableLoanTerms, selectApprovedLoanTerms } from '../../db/client_selectLoanTerms';
import {
    clientCreateTokensPortfolio as createTokensPortfolio
} from '../../db/clientCreateTokensPortfolio';
import {
    clientUpdatePortfolioLeveragedStatus as updatePortfolioLeveragedStatus
} from '../../db/clientUpdateTokensPortfolio';
import {
    clientUpdateLeveragedLenderSigned as updateLeveragedLenderSigned
} from '../../db/clientUpdateTokensLeveraged';
import {
    clientReadNonSponsoredTokensLeveragedContract as readNonSponsoredTokensLeveragedContract
} from '../../db/clientReadTokensLeveraged';

import {
    clientReadNonSponsoredTokensJoin as readNonSponsoredTokensJoin
} from '../../db/clientReadJoin';

import { clientReadLeveragedTokensPortfolio as readLeveragedTokensPortfolio } from '../../db/clientReadTokensPortfolio';
import { updateTokensLeveraged } from '../../db/clientCreateTokensLeveraged';

import abi_LoanContract from '../../artifacts/LoanContract.sol/LoanContract.json';
import abi_ERC721 from '../../artifacts/ERC721.sol/ERC721.json';

export default function LendingPage() {
    const [isPageLoad, setIsPageLoad] = useState(true);
    const [newContract, setNewContract] = useState('');
    const [currentAccount, setCurrentAccount] = useState(null);
    const [currentChainId, setCurrentChainId] = useState(null);
    const [currentLoanProposalsTable, setCurrentLoanProposalsTable] = useState(null);
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
        if (!!newContract) newContractSponsoredSequence();
    }, [newContract])

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
        const loanProposals = await getLoanProposals(ownedNfts)

        // Render table of potential NFTs
        const [proposedLoansTable, token] = await NftTable({
            account: account,
            nfts: loanProposals,
            type: "sponsor",
            useDefaultTerms: false,
            disabledOverriden: true,
        });

        token !== null && setCurrentToken({ address: token.address, id: token.id });
        proposedLoansTable !== null && setCurrentLoanProposalsTable(proposedLoansTable);

        setIsPageLoad(false);
    }

    const tokenSelectionChangeSequence = async () => {
        // Update current selection
        // console.log(`Token change seq: ${currentToken.address}-${currentToken.id}`);
    }

    const newContractSponsoredSequence = async () => {
        // console.log('new contract created!');

        // await updatePortfolioLeveragedStatus(newContract, 'Y');

        // // Render table of potential NFTs
        // const [leveragedNftsTable, _] = await renderNftTable(currentAccount);
        // setCurrentLoanProposalsTable(leveragedNftsTable);

        // window.location.reload();

        // setNewContract('');
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

        terms["collateral"] = `${collateralAddress}_${collateralId}`

        const response = (await selectApprovedLoanTerms(
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

        console.log(response);

        // Set LoanContractFactory to operator
        const LoanContract = new ethers.Contract(
            config[currentChainId].LoanContract,
            abi_LoanContract.abi,
            signer
        );

        // const tx = await LoanContract.connect(signer)[
        //     "initLoanContract()"
        // ](
        //     { gasLimit: 10000000 }
        //     // { value: response["principal"], gasLimit: 1000000 }
        // );
        console.log(response["principal"]);

        const tx = await LoanContract.connect(signer)[
            "initLoanContract(bytes32,address,uint256,bytes)"
        ](
            response["packed_contract_terms"],
            collateralAddress,
            collateralId,
            response["signed_message"],
            { value: response["principal"], gasLimit: 1000000 }
        );

        const receipt = await tx.wait();
        console.log(receipt);

        // const [_collateralAddress, _collateralId, _debtId] = await listenerLoanContractInit(tx, LoanContract);

        // console.log(`collateralAddress: ${_collateralAddress}`);
        // console.log(`collateralId: ${_collateralId}`);
        // console.log(`debtId: ${_debtId}`);

        // setNewContract(primaryKey);
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
                `${ownedNfts[i].contract.address.toLowerCase()}_${ownedNfts[i].tokenId}`
            )
        });

        const data = await selectAvailableLoanTerms(collateral);

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
                <h2>Available for Sponsor</h2>
                <div className='buttongroup buttongroup-body'>
                    <div className='button button-body' onClick={callback__SponsorLoanContract}>Sponsor Loan</div>
                </div>
                {currentLoanProposalsTable}
            </div>
        </main>
    );
}
