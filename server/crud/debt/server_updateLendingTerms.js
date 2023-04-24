const { dbQueryPost, dbQueryGet } = require('../common/queryTemplates');

// 2.0.0 :: Update the loans proposal as approved.
const dbUpdateApprovedLendingTerms = (app, db) => {
    app.post('/api/update/approve/lending_terms', async (req, res) => {
        const signedMessage = "'" + req.body.signedMessage + "'";
        const debtId = "'" + req.body.debtId + "'";

        let query = `
            UPDATE anza_loans.lending_terms
            SET debt_id=${debtId}
            WHERE signed_message=${signedMessage}
        `;

        dbQueryPost(
            db,
            res,
            query,
            [debtId]
        );
    });
}


// 2.0.1 :: Update the loan proposals to unallowed.
const dbUpdateUnallowedLendingTerms = (app, db) => {
    app.post('/api/update/unallowed/lending_terms', async (req, res) => {
        const collateral = "'" + req.body.collateral + "'";

        let query = `
            UPDATE anza_loans.lending_terms
            SET allowed=${0}
            WHERE collateral=${collateral}
        `;

        dbQueryPost(
            db,
            res,
            query,
            [0]
        );
    });
}


// 2.0.2 :: Update the loan proposals to rejected.
const dbUpdateRejectedLendingTerms = (app, db) => {
    app.post('/api/update/rejected/lending_terms', async (req, res) => {
        const collateral = "'" + req.body.collateral + "'";

        let query = `
            UPDATE anza_loans.lending_terms
            SET rejected=${1}
            WHERE collateral=${collateral}
            AND debt_id IS NULL
        `;

        dbQueryPost(
            db,
            res,
            query,
            [0]
        );
    });
}

module.exports = {
    dbUpdateApprovedLendingTerms,
    dbUpdateUnallowedLendingTerms,
    dbUpdateRejectedLendingTerms
};