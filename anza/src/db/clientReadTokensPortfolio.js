import axios from 'axios';
import config from '../config.json';

export const clientReadNonLeveragedTokensPortfolio = async (ownerAddress) => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/portfolio/${ownerAddress}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

export const clientReadLeveragedTokensPortfolio = async (ownerAddress) => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/portfolio/${ownerAddress}`;

    console.log(`${domain}${endpoints}`);

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};