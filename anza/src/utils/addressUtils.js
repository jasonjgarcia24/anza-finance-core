export const getSubAddress = (fullAddress) => {
    return `${fullAddress.slice(0, 5)}...${fullAddress.slice(-4)}`;
}

