const { dbQueryPost } = require('../common/queryTemplates');

// 0.1.0 :: Inserts the lender's newly confirmed sponsored loan.
const dbInsertConfirmedLoans = (app, db) => {
    app.post('/api/insert/confirmed_loans', (req, res) => {
        const debtId = req.body.debtId;
        const borrower = req.body.borrower;
        const lender = req.body.lender;
        const activeLoanIndex = req.body.activeLoanIndex;
        const loanStartTime = req.body.loanStartTime;
        const loanEndTime = req.body.loanEndTime;

        let query = `INSERT INTO anza_loans.confirmed_loans(
            debt_id,
            borrower,
            lender,
            active_loan_index,
            loan_start_time,
            loan_end_time
        ) VALUES (?, ?, ?, ?, ?, ?);`;

        dbQueryPost(
            db,
            res,
            query,
            [
                debtId,
                borrower,
                lender,
                activeLoanIndex,
                loanStartTime,
                loanEndTime
            ]
        );
    });
}

module.exports = { dbInsertConfirmedLoans };