export const getSubAddress = (fullAddress) => {
    return `${fullAddress.slice(0, 5)}...${fullAddress.slice(-4)}`;
}

export const getSubCid = (fullCid) => {
    const justCid = fullCid.replace("ipfs://", "");
    return `${justCid.slice(0, 5)}...${justCid.slice(-4)}`;
}

