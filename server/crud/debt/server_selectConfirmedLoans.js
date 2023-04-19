const { dbQueryGet } = require('../common/queryTemplates');

// 0.1.0 :: Selects the lender's sponsored loans.
const dbSelectConfirmedLoans = (app, db) => {
    app.get('/api/select/sponsored/confirmed_loans/all',
        async (req, res) => {
            let query = `
                SELECT 
                *
                FROM anza_loans.confirmed_loans cl
                INNER JOIN anza_loans.lending_terms lt
                ON cl.debt_id = lt.debt_id
                ORDER BY cl.debt_id ASC;
            `

            await dbQueryGet(db, res, query);
        });
}

// 0.1.1 :: Selects the lender's sponsored loans.
const dbSelectSponsoredConfirmedLoans = (app, db) => {
    app.get('/api/select/sponsored/confirmed_loans/:lender',
        async (req, res) => {
            const lender = req.params.lender;

            let query = `
                SELECT 
                *
                FROM anza_loans.confirmed_loans cl
                INNER JOIN anza_loans.lending_terms lt
                ON cl.debt_id = lt.debt_id
                WHERE cl.lender = ${lender} 
                ORDER BY cl.debt_id ASC;
            `

            await dbQueryGet(db, res, query);
        });
}

module.exports = {
    dbSelectConfirmedLoans,
    dbSelectSponsoredConfirmedLoans
};