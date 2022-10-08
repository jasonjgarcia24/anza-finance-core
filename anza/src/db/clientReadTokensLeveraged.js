import axios from 'axios';
import { ethers } from 'ethers';
import config from '../config.json';

export const clientReadNonSponsoredTokensLeveraged = async () => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/leveraged/all/lender/unsigned/${ethers.constants.AddressZero}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

export const clientReadNonSponsoredTokensLeveragedContract = async (tokenContractAddress, tokenId) => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/leveraged/loancontract/${tokenContractAddress}/${tokenId}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data[0];
};

export const clientReadSignedTokensLeveraged = async (lenderAddress) => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/leveraged/all/lender/signed/${lenderAddress}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};
