const { dbQueryGet } = require('../common/queryTemplates');

// 2.0.0 :: Selects the lender's sponsored loans.
const dbSelectSponsoredConfirmedLoans = (app, db) => {
    app.get('/api/select/sponsored/confirmed_loans/:lender'
        , async (req, res) => {
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
    dbSelectSponsoredConfirmedLoans
};