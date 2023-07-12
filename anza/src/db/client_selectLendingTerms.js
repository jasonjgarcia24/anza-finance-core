import axios from 'axios';
import config from '../config.json';

// 1.0.0 :: Selects the borrower's proposed loans.
export const selectProposedLoanTerms = async (collateral) => {
    const _collateral = "'" + collateral.join("','") + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/proposed/lending_terms/${_collateral}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 1.0.1 :: Selects a specific proposed loan.
export const selectAtProposedLoanTerms = async (collateral) => {
    const _collateral = "'" + collateral + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/at_proposed/lending_terms/${_collateral}`;


    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 1.0.2 :: Selects the lender's available loans for sponsorship.
export const selectAvailableLoanTerms = async (ownedNfts, account) => {
    const _ownedNfts = "'" + ownedNfts.join("','") + "'";
    const _account = "'" + account.toLowerCase() + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/available/lending_terms/${_ownedNfts}/${_account}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 1.0.3 :: Selects the lender's approved loan for sponsorship.
export const selectApprovedLoanTerms = async (
    collateral,
    isFixed,
    principal,
    fixedInterestRate,
    firInterval,
    gracePeriod,
    duration,
    commital,
    termsExpiry,
    lenderRoyalties
) => {
    const _collateral = "'" + collateral + "'";
    const _isFixed = isFixed;
    const _principal = "'" + principal + "'";
    const _fixedInterestRate = "'" + fixedInterestRate + "'";
    const _firInterval = "'" + firInterval + "'";
    const _gracePeriod = "'" + gracePeriod + "'";
    const _duration = "'" + duration + "'";
    const _commital = "'" + commital + "'";
    const _termsExpiry = "'" + termsExpiry + "'";
    const _lenderRoyalties = "'" + lenderRoyalties + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/approved/lending_terms/` +
        `${_collateral}/` +
        `${_isFixed}/` +
        `${_principal}/` +
        `${_fixedInterestRate}/` +
        `${_firInterval}/` +
        `${_gracePeriod}/` +
        `${_duration}/` +
        `${_commital}/` +
        `${_termsExpiry}/` +
        `${_lenderRoyalties}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};

// 1.0.4 :: Selects the borrower's proposed refinanced loans.
export const selectProposedRefinanceLoanTerms = async (collateral, borrower) => {
    const _collateral = "'" + collateral.join("','") + "'";
    const _borrower = "'" + borrower.toLowerCase() + "'";

    const domain = `http://${config.SERVER.HOST}:${config.SERVER.PORT}`;
    const endpoints = `/api/select/proposed_refinance/lending_terms/${_collateral}/${_borrower}`;

    const { data } = await axios.get(`${domain}${endpoints}`);

    return data;
};
