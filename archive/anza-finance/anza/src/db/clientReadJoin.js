import axios from 'axios';
import { ethers } from 'ethers';
import config from '../config.json';

export const clientReadBorrowerNotSignedJoin = async (account) => {
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/join/borrowerSignedNull/${account}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
}

export const clientReadNonSponsoredTokensJoin = async (accountAddress) => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/join/unsponsored/${ethers.constants.AddressZero}/${accountAddress}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};