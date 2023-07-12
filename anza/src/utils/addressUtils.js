import config from '../config.json';

export const getSubAddress = (fullAddress) => {
    return `${fullAddress.slice(0, 5)}...${fullAddress.slice(-4)}`;
}

export const getLinkedSubAddress = (fullAddress, chainId='1') => {
    return (<a href={`${config.ETHERSCAN[chainId]}address/${fullAddress}`} target="_blank">{fullAddress.slice(0, 5)}...{fullAddress.slice(-4)}</a>);
}

export const getSubCid = (fullCid) => {
    const justCid = fullCid.replace("ipfs://", "");
    return `${justCid.slice(0, 5)}...${justCid.slice(-4)}`;
}

