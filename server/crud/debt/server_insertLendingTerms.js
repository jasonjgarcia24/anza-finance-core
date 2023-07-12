const { dbQueryPost } = require("../common/queryTemplates");

// 0.0.0 :: Inserts the borrower's newly proposed loans.
const dbInsertProposedLendingTerms = (app, db) => {
    app.post("/api/insert/lending_terms", (req, res) => {
        const signedMessage = req.body.signedMessage;
        const packedContractTerms = req.body.packedContractTerms;
        const borrower = req.body.borrower;
        const collateral = req.body.collateral;
        const collateralNonce = req.body.collateralNonce;
        const isFixed = req.body.isFixed;
        const principal = req.body.principal;
        const fixedInterestRate = req.body.fixedInterestRate;
        const firInterval = req.body.firInterval;
        const gracePeriod = req.body.gracePeriod;
        const duration = req.body.duration;
        const commital = req.body.commitalRatio;
        const termsExpiry = req.body.termsExpiry;
        const lenderRoyalties = req.body.lenderRoyalties;
        const refinanceDebtId = req.body.refinanceDebtId;

        let query = `INSERT INTO anza_loans.lending_terms(
                    signed_message,
                    packed_contract_terms,
                    borrower,
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
                    debt_id,
                    refinance_debt_id
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);`;

        console.log(refinanceDebtId);

        dbQueryPost(db, res, query, [
            signedMessage,
            packedContractTerms,
            borrower,
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
            null,
            refinanceDebtId,
        ]);
    });
};

module.exports = { dbInsertProposedLendingTerms };
