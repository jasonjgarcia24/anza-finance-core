const { dbQueryGet } = require("../common/queryTemplates");

// 1.0.0 :: Selects the borrower's proposed loans.
const dbSelectProposedLendingTerms = (app, db) => {
    app.get(
        "/api/select/proposed/lending_terms/:collateral",
        async (req, res) => {
            const collateral = req.params.collateral;

            let query = `
            SELECT 
            *
            FROM anza_loans.lending_terms
            WHERE collateral IN (${collateral})
            ORDER BY collateral ASC;
        `;

            await dbQueryGet(db, res, query);
        }
    );
};

// 1.0.1 :: Selects a specific proposed loan.
const dbSelectAtProposedLendingTerms = (app, db) => {
    app.get(
        "/api/select/at_proposed/lending_terms/:collateral",
        async (req, res) => {
            const collateral = req.params.collateral;

            let query = `
            SELECT 
            *
            FROM anza_loans.lending_terms
            WHERE collateral = ${collateral}
            ORDER BY collateral ASC;
        `;

            await dbQueryGet(db, res, query);
        }
    );
};

// 1.0.2 :: Selects the lender's available loans for sponsorship.
const dbSelectAvailableLendingTerms = (app, db) => {
    app.get(
        "/api/select/available/lending_terms/:collateral/:account",
        async (req, res) => {
            const collateral = req.params.collateral;
            const account = req.params.account;
            console.log(account);
            console.log(collateral);

            let query = `
            SELECT 
            *
            FROM 
                anza_loans.lending_terms lt
                INNER JOIN anza_loans.confirmed_loans cl ON lt.refinance_debt_id = cl.debt_id
            WHERE 
                lt.collateral NOT IN (${collateral}) 
                AND lt.allowed = true
                AND cl.borrower != ${account}
            ORDER BY collateral ASC;
        `;

            await dbQueryGet(db, res, query);
        }
    );
};

// 1.0.3 :: Selects the lender's approved loan for sponsorship.
const dbSelectApprovedLendingTerms = (app, db) => {
    app.get(
        "/api/select/approved/lending_terms/" +
            ":collateral/" +
            ":is_fixed/" +
            ":principal/" +
            ":fixed_interest_rate/" +
            ":fir_interval/" +
            ":grace_period/" +
            ":duration/" +
            ":commital/" +
            ":terms_expiry/" +
            ":lender_royalties",
        async (req, res) => {
            const collateral = req.params.collateral;
            const is_fixed = req.params.is_fixed;
            const principal = req.params.principal;
            const fixed_interest_rate = req.params.fixed_interest_rate;
            const fir_interval = req.params.fir_interval;
            const grace_period = req.params.grace_period;
            const duration = req.params.duration;
            const commital = req.params.commitalRatio;
            const terms_expiry = req.params.terms_expiry;
            const lender_royalties = req.params.lender_royalties;

            let query = `
                SELECT 
                *
                FROM anza_loans.lending_terms
                WHERE collateral = ${collateral} 
                AND is_fixed = ${is_fixed} 
                AND principal = ${principal} 
                AND fixed_interest_rate = ${fixed_interest_rate} 
                AND fir_interval = ${fir_interval} 
                AND grace_period = ${grace_period} 
                AND duration = ${duration} 
                AND commital = ${commital} 
                AND terms_expiry = ${terms_expiry} 
                AND lender_royalties = ${lender_royalties}
                ORDER BY collateral ASC;
            `;

            await dbQueryGet(db, res, query);
        }
    );
};

// 1.0.4 :: Selects the borrower's proposed refinanced loans.
const dbSelectProposedRefinanceLoanTerms = (app, db) => {
    app.get(
        "/api/select/proposed_refinance/lending_terms/:collateral/:borrower",
        async (req, res) => {
            const collateral = req.params.collateral;
            const borrower = req.params.borrower;

            let query = `
            SELECT 
            *
            FROM anza_loans.lending_terms
            WHERE collateral NOT IN (${collateral})
            AND borrower = ${borrower}
            AND debt_id IS NULL
            AND rejected = false
            ORDER BY collateral ASC;
        `;

            await dbQueryGet(db, res, query);
        }
    );
};

module.exports = {
    dbSelectProposedLendingTerms,
    dbSelectAtProposedLendingTerms,
    dbSelectAvailableLendingTerms,
    dbSelectApprovedLendingTerms,
    dbSelectProposedRefinanceLoanTerms,
};
