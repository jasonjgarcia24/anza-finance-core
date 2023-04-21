import { ethers } from 'ethers';
import config from '../../config.json';
import { getSubAddress } from '../../utils/addressUtils';

const getEmptyString = (type) => {
    return {
        proposal: "🌵 You do not have any loan proposals yet 🌵",
        terms: "🪹 No available collateral 🪹",
        confirmed: "🙈 You do not have any sponsored loans yet 🙈",
        sponsor: "🌵 No loan proposals available for sponsorship 🌵"
    }[type]
}

/* ---------------------------------------  *
 *             TABLE HEADERS                *
 * ---------------------------------------  */
const nftsHeaders = [
    "Contract",
    "Token ID",
    "Fixed Loan",
    "Principal",
    "Fixed Interest Rate (FIR)",
    "FIR Interval",
    "Grace Period (sec)",
    "Duration (sec)",
    "Commital (%)",
    "Terms Expiry (sec)",
    "Lender Royalties (%)"
];

const loanHeaders = [
    "Contract",
    "Token ID",
    "Fixed Loan",
    "Principal",
    "Fixed Interest Rate (FIR)",
    "FIR Interval",
    "Grace Period",
    "Loan Start",
    "Loan Commitment",
    "Loan Close",
    "Lender Royalties (%)"
];

/* ---------------------------------------  *
 *             DATA PARSERS                 *
 * ---------------------------------------  */
const getDefaultTermsValue = (term, nft) => {
    return term !== "principal"
        ? nft[term]
        : ethers.utils.formatEther(nft[term]);
}


const getDefaultLoanValue = (term, nft) => {
    switch (true) {
        case term === "principal":
            return ethers.utils.formatEther(nft[term]);
        case ["loan_start_time", "loan_commit_time", "loan_end_time"].includes(term):
            const date = new Date(parseInt(nft[term]) * 1000);

            let opt = {
                year: '2-digit',
                month: '2-digit',
                day: 'numeric',
                hour: 'numeric',
                minute: 'numeric',
                hour12: false
            };

            return date.toLocaleDateString('en-US', opt);
        default:
            return nft[term];
    }
}


/* ---------------------------------------  *
 *          ELEMENT IDENTIFIERS             *
 * ---------------------------------------  */
const setEnableControlId = (term, rowObj) => {
    return `${term}-${rowObj.contract.address}-${rowObj.tokenId}-${rowObj.tableType}`
}

export const setName = (term, rowObj) => {
    return `${term}-${rowObj.contract.address}-${rowObj.tokenId}-${rowObj.tableType}-${rowObj.index}`
}

/* ---------------------------------------  *
 *           ELEMENT GENERATORS             *
 * ---------------------------------------  */
const rowSelector = (account, callbackRadioButton, rowObj) => {
    return <td
        key={`td-radio-${rowObj.contract.address}-${rowObj.tokenId}`}
        id={`id-radio-${rowObj.contract.address}-${rowObj.tokenId}`}
    >
        <input
            type='radio'
            key={`radio-${rowObj.contract.address}-${rowObj.tokenId}-${rowObj.index}`}
            id={`${rowObj.tableType}-${rowObj.contract.address}-${rowObj.tokenId}`}
            name={`radio-${account}`}
            className={`radio-${rowObj.tableType}`}
            value={`${rowObj.contract.address}-${rowObj.tokenId}-${rowObj.tableType}-${rowObj.index}`}
            defaultChecked={rowObj.index === '0'}
            onClick={callbackRadioButton}
        />
    </td>
}

const isFixedSelector = (callbackSelect, disabledOverriden, rowObj) => {
    return <select
        key={`text-is_fixed-${rowObj.contract.address}-${rowObj.tokenId}-${rowObj.index}`}
        id={setEnableControlId("is_fixed", rowObj)}
        name={setName("is_fixed", rowObj)}
        className={`loan-term is_fixed-${rowObj.contract.address}-${rowObj.tokenId}`}
        onChange={callbackSelect}
        disabled={disabledOverriden || rowObj.index !== '0'}
    >
        <option>N</option><option>Y</option>
    </select>
}

const isFixedDisplay = (rowObj) => {
    return <input
        type='text'
        key={`text-is_fixed-${rowObj.contract.address}-${rowObj.tokenId}-${rowObj.index}`}
        id={setEnableControlId("is_fixed", rowObj)}
        name={setName("is_fixed", rowObj)}
        className={`loan-term is_fixed-${rowObj.contract.address}-${rowObj.tokenId}`}
        defaultValue={rowObj.is_fixed ? "Y" : "N"}
        disabled={true}
    />
}

/*
 *  Borrower Page
 *    - Loan Proposals
 *    - Available Collateral
 *  Lender Page
 *    - Available for Sponsor
 */
export const NftTable = async (nftTableObj) => {
    const renderNftTable = async ({
        account = null,
        nfts = {},
        type = "terms",
        useDefaultTerms = false,
        disabledOverriden = false,
        callbackRadioButton = null,
        callbackSelect = null
    }) => {
        if (!account) { return [null, { address: null, id: null }]; }

        // Create token elements
        const tokenElements = [];
        tokenElements.push(
            Object.keys(nfts).map((i) => {
                // If loading from database
                if (['proposal', 'sponsor', 'confirmed', 'commits', 'open'].includes(type)) {
                    nfts[i].contract = {};
                    [nfts[i].contract.address, nfts[i].tokenId] = nfts[i].collateral.split("_");
                }

                nfts[i].tokenId = parseInt(nfts[i].tokenId, 10).toString();
                nfts[i].tableType = type;
                nfts[i].index = i;

                return (
                    <tr key={`tr-${nfts[i].contract.address}-${nfts[i].tokenId}-${i}`}>
                        {/* RADIO BUTTON */}
                        {
                            !['proposal', 'confirmed', 'commits'].includes(type)
                            && rowSelector(account, callbackRadioButton, nfts[i])
                        }
                        {/* COLLATERAL ADDRESS */}
                        <td
                            key={`address-${nfts[i].contract.address}-${nfts[i].tokenId}-${i}`}
                            id={`collateral_address-${nfts[i].contract.address}-${nfts[i].tokenId}-${type}-${i}`}
                        >{getSubAddress(nfts[i].contract.address)}
                        </td>
                        {/* COLLATERAL ID */}
                        <td
                            key={`token_id-${nfts[i].contract.address}-${nfts[i].tokenId}-${i}`}
                            id={`collateral_id-${nfts[i].contract.address}-${nfts[i].tokenId}-${type}-${i}`}
                        >{nfts[i].tokenId}
                        </td>
                        {/* IS FIXED? */}
                        <td>
                            {
                                !['proposal', 'sponsor'].includes(type) &&
                                isFixedSelector(callbackSelect, disabledOverriden, nfts[i]) ||
                                isFixedDisplay(nfts[i])
                            }
                        </td>
                        {/* LENDING TERMS */}
                        {
                            renderLenderTerms(
                                {
                                    nft: nfts[i],
                                    useDefaultTerms: useDefaultTerms,
                                    disabled: disabledOverriden || (i !== '0')
                                }
                            )
                        }
                    </tr >
                )
            })
        );

        const availableNftsTable = (
            <form className='form-table form-table-available-nfts'>
                <table className='table-available-nfts'>
                    <thead><tr>
                        {!['proposal', 'confirmed', 'commits'].includes(type) && <th></th>}
                        {
                            ['proposal', 'terms', 'sponsor'].includes(type) &&
                            nftsHeaders.map((hdr, index) => {
                                return <th key={`${type}-${index}`}><label>{hdr}</label></th>
                            }) ||
                            loanHeaders.map((hdr, index) => {
                                return <th key={`${type}-${index}`}><label>{hdr}</label></th>
                            })
                        }
                    </tr></thead>
                    <tbody>
                        {tokenElements}
                    </tbody>
                </table>
            </form>
        );

        return nfts.length > 0
            ? [
                availableNftsTable,
                { address: nfts[0].contract.address, id: nfts[0].tokenId }
            ]
            : [<div>{getEmptyString(type)}</div>, null];
    }

    const renderLenderTerms = ({
        nft = {},
        useDefaultTerms = false,
        disabled = false,
    }) => {
        const termObj = {
            "principal": config.DEFAULT_TEST_VALUES.PRINCIPAL,
            "fixed_interest_rate": config.DEFAULT_TEST_VALUES.FIXED_INTEREST_RATE,
            "fir_interval": config.DEFAULT_TEST_VALUES.FIR_INTERVAL,
            "grace_period": config.DEFAULT_TEST_VALUES.GRACE_PERIOD,
            "duration": config.DEFAULT_TEST_VALUES.DURATION,
            "commital": config.DEFAULT_TEST_VALUES.COMMITAL,
            "terms_expiry": config.DEFAULT_TEST_VALUES.TERMS_EXPIRY,
            "lender_royalties": config.DEFAULT_TEST_VALUES.LENDER_ROYALTIES,
        }

        return Object.keys(termObj).map((term) => {
            let defaultValue;

            if (!['proposal', 'confirmed', 'commits'].includes(nft.tableType)) {
                defaultValue = useDefaultTerms ? termObj[term] : getDefaultTermsValue(term, nft);
            } else {
                defaultValue = getDefaultLoanValue(term, nft);
            }

            return (
                < td key={`td-${term}-${nft.contract.address}-${nft.tokenId}_${nft.index}`
                } id={`id-text-${nft.contract.address}-${nft.tokenId}`}>
                    <input
                        type='text'
                        key={`text-${term}-${nft.contract.address}-${nft.tokenId}-${nft.index}`}
                        id={setEnableControlId(term, nft)}
                        name={setName(term, nft)}
                        className={`loan-term ${term}-${nft.contract.address}-${nft.tokenId}`}
                        defaultValue={defaultValue}
                        disabled={disabled}
                    />
                </td >
            )
        });
    }

    return renderNftTable(nftTableObj);
}
