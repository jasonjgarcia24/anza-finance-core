import axios from 'axios';
import config from '../config.json';

// 0.1.0 :: Selects the all confirmed loans.
export const selectConfirmedLoans = async () => {
    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/sponsored/confirmed_loans/all`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 0.1.1 :: Selects the lender's sponsored confirmed loans.
export const selectSponsoredConfirmedLoans = async (lender) => {
    const _lender = "'" + lender.toLowerCase() + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/sponsored/confirmed_loans/${_lender}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 0.1.2 :: Selects the borrower's open confirmed loans.
export const selectOpenConfirmedLoans = async (borrower, current_time) => {
    const _borrower = "'" + borrower.toLowerCase() + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/open/confirmed_loans/${_borrower}/${current_time}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 0.1.3 :: Selects the borrower's committed confirmed loans.
export const selectCommittedConfirmedLoans = async (borrower, current_time) => {
    const _borrower = "'" + borrower.toLowerCase() + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/committed/confirmed_loans/${_borrower}/${current_time}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};
