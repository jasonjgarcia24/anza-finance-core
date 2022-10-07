import axios from 'axios';
import config from '../config.json';

export const readNonLeveragedTokensPortfolio = async (ownerAddress) => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/portfolio/${ownerAddress}/N`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

export const readLeveragedTokensPortfolio = async (ownerAddress) => {  
    const domain = `http://${config.DATABASE.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/portfolio/${ownerAddress}/Y`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};