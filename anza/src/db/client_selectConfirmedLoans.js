import axios from 'axios';
import config from '../config.json';

// 0.1.1 :: Selects the lender's sponsored loans.
export const selectConfirmedLoans = async () => {
    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/sponsored/confirmed_loans/all`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 0.1.1 :: Selects the lender's sponsored loans.
export const selectSponsoredConfirmedLoans = async (lender) => {
    const _lender = "'" + lender + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/sponsored/confirmed_loans/${_lender}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};
