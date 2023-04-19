import { ethers } from 'ethers';
import config from '../../config.json';
import { getSubAddress } from '../../utils/addressUtils';


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
                if (['proposal', 'sponsor', 'confirmed', 'committed', 'open'].includes(type)) {
                    nfts[i].contract = {};
                    [nfts[i].contract.address, nfts[i].tokenId] = nfts[i].collateral.split("_");
                }

                nfts[i].tokenId = parseInt(nfts[i].tokenId, 10).toString();

                return (
                    <tr key={`tr-${nfts[i].contract.address}-${nfts[i].tokenId}-${i}`}>
                        {/* RADIO BUTTON */}
                        {!['proposal', 'confirmed'].includes(type) && <td key={`td-radio-${nfts[i].contract.address}-${nfts[i].tokenId}`} id={`id-radio-${nfts[i].contract.address}-${nfts[i].tokenId}`}>
                            <input
                                type='radio'
                                key={`radio-${nfts[i].contract.address}-${nfts[i].tokenId}-${i}`}
                                id={`${type}-${nfts[i].contract.address}-${nfts[i].tokenId}`}
                                name={`radio-${account}`}
                                className={`radio-${type}`}
                                value={`${nfts[i].contract.address}-${nfts[i].tokenId}-${type}-${i}`}
                                defaultChecked={i === '0'}
                                onClick={callbackRadioButton}
                            />
                        </td>
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
                            <select
                                key={`text-is_fixed-${nfts[i].contract.address}-${nfts[i].tokenId}-${i}`}
                                id={`is_fixed-${nfts[i].contract.address}-${nfts[i].tokenId}-${type}`}
                                name={`is_fixed-${nfts[i].contract.address}-${nfts[i].tokenId}-${i}`}
                                className={`is_fixed-${nfts[i].contract.address}-${nfts[i].tokenId}`}
                                onChange={callbackSelect}
                                disabled={disabledOverriden || i !== '0'}
                            >
                                <option>N</option><option>Y</option>
                            </select>
                        </td>
                        {/* LENDING TERMS */}
                        {renderLenderTerms(
                            {
                                nft: nfts[i],
                                type: type,
                                index: i,
                                useDefaultTerms: useDefaultTerms,
                                disabled: disabledOverriden || (i !== '0')
                            }
                        )}
                    </tr >
                )
            })
        );

        const availableNftsTable = (
            <form className='form-table form-table-available-nfts'>
                <table className='table-available-nfts'>
                    <thead><tr>
                        {!['proposal', 'confirmed', 'committed'].includes(type) && <th></th>}
                        <th><label>Contract</label></th>
                        <th><label>Token ID</label></th>
                        <th><label>Fixed Loan</label></th>
                        <th><label>Principal</label></th>
                        <th><label>Fixed Interest Rate (FIR)</label></th>
                        <th><label>FIR Interval</label></th>
                        <th><label>Grace Period (sec)</label></th>
                        <th><label>Duration (sec)</label></th>
                        <th><label>Commital (%)</label></th>
                        <th><label>Terms Expiry (sec)</label></th>
                        <th><label>Lender Royalties (%)</label></th>
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

    const getEmptyString = (type) => {
        return {
            proposal: "🌵 You do not have any loan proposals yet 🌵",
            terms: "🪹 No available collateral 🪹",
            confirmed: "🙈 You do not have any sponsored loans yet 🙈",
            sponsor: "🌵 No loan proposals available for sponsorship 🌵"
        }[type]
    }

    const renderLenderTerms = ({
        nft = {},
        type = "",
        index = 0,
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
            return (
                < td key={`td-${term}-${nft.contract.address}-${nft.tokenId}_${index}`
                } id={`id-text-${nft.contract.address}-${nft.tokenId}`}>
                    <input
                        type='text'
                        key={`text-${term}-${nft.contract.address}-${nft.tokenId}-${index}`}
                        id={`${term}-${nft.contract.address}-${nft.tokenId}-${type}`}
                        name={`${term}-${nft.contract.address}-${nft.tokenId}-${index}`}
                        className={`loan-term-text ${term}-${nft.contract.address}-${nft.tokenId}`}
                        defaultValue={useDefaultTerms ? termObj[term] : term !== "principal" ? nft[term] : ethers.utils.formatEther(nft[term])}
                        disabled={disabled}
                    />
                </td >
            )
        });
    }

    return renderNftTable(nftTableObj);
}
