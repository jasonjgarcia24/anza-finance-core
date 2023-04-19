const { dbQueryPost, dbQueryGet } = require('../common/queryTemplates');

// 1.0.0 :: Update the loans proposal as approved.
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


// 1.1.0 :: Update the loan proposals with matching collateral to unallowed.
const dbUpdateUnallowedCollateralLendingTerms = (app, db) => {
    app.post('/api/update/collateral_unallowed/lending_terms', async (req, res) => {
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

module.exports = {
    dbUpdateApprovedLendingTerms,
    dbUpdateUnallowedCollateralLendingTerms
};