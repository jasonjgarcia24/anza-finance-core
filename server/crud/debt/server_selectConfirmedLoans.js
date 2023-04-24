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

// 0.1.2 :: Selects the borrower's open confirmed loans.
const dbSelectOpenConfirmedLoans = (app, db) => {
    app.get('/api/select/open/confirmed_loans/:borrower/:current_time',
        async (req, res) => {
            const borrower = req.params.borrower;
            const current_time = parseInt(req.params.current_time)

            let query = `
                SELECT *\
                FROM
                    anza_loans.confirmed_loans cl
                    INNER JOIN anza_loans.lending_terms lt ON cl.debt_id = lt.debt_id
                WHERE
                    cl.borrower = ${borrower}
                    AND UNIX_TIMESTAMP(
                        FROM_UNIXTIME(cl.loan_commit_time)
                    ) < ${current_time}
                ORDER BY cl.debt_id ASC;
            `

            console.log(query);

            await dbQueryGet(db, res, query);
        });
}

// 0.1.3 :: Selects the borrower's committed confirmed loans.
const dbSelectCommittedConfirmedLoans = (app, db) => {
    app.get('/api/select/committed/confirmed_loans/:borrower/:current_time',
        async (req, res) => {
            const borrower = req.params.borrower;
            const current_time = parseInt(req.params.current_time)

            let query = `
                SELECT *\
                FROM
                    anza_loans.confirmed_loans cl
                    INNER JOIN anza_loans.lending_terms lt ON cl.debt_id = lt.debt_id
                WHERE
                    cl.borrower = ${borrower}
                    AND UNIX_TIMESTAMP(
                        FROM_UNIXTIME(cl.loan_commit_time)
                    ) >= ${current_time}
                ORDER BY cl.debt_id ASC;
            `

            console.log(query);

            await dbQueryGet(db, res, query);
        });
}

module.exports = {
    dbSelectConfirmedLoans,
    dbSelectSponsoredConfirmedLoans,
    dbSelectOpenConfirmedLoans,
    dbSelectCommittedConfirmedLoans
};