import config from '../config.json';

export const getNetworkName = (chainId) => {
    return config.CHAINID_TO_NETWORK[chainId] || 'Network Unknown';
}