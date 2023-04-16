const { dbQueryPost } = require('../common/queryTemplates');

// 1.0.0 :: Inserts the borrower's proposed loans.
const dbInsertProposedLoanTerms = (app, db) => {
    app.post('/api/insert/lending_terms', (req, res) => {
        const signedMessage = req.body.signedMessage;
        const packedContractTerms = req.body.packedContractTerms;
        const collateral = req.body.collateral;
        const collateralNonce = req.body.collateralNonce;
        const isFixed = req.body.isFixed;
        const principal = req.body.principal;
        const fixedInterestRate = req.body.fixedInterestRate;
        const firInterval = req.body.firInterval;
        const gracePeriod = req.body.gracePeriod;
        const duration = req.body.duration;
        const commital = req.body.commital;
        const termsExpiry = req.body.termsExpiry;
        const lenderRoyalties = req.body.lenderRoyalties;

        let query = `INSERT INTO anza_loans.lending_terms(
                    signed_message,
                    packed_contract_terms,
                    collateral,
                    collateral_nonce,
                    is_fixed,
                    principal,
                    fixed_interest_rate,
                    fir_interval,
                    grace_period,
                    duration,
                    commital,
                    terms_expiry,
                    lender_royalties,
                    debt_id
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);`;

        dbQueryPost(
            db,
            res,
            query,
            [
                signedMessage,
                packedContractTerms,
                collateral,
                collateralNonce,
                isFixed,
                principal,
                fixedInterestRate,
                firInterval,
                gracePeriod,
                duration,
                commital,
                termsExpiry,
                lenderRoyalties,
                null
            ]
        );
    });
}

module.exports = { dbInsertProposedLoanTerms };