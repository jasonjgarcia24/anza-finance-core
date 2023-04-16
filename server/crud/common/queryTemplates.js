const dbQueryGet = async (db, res, query) => {
    db.query(
        query,
        (err, results) => {
            if (err) {
                const errObj = {
                    message: "Error selecting from database!",
                    error: err
                }
                res.status(500).json(errObj);
            } else {
                console.log("Loan data delivered successfully!");
                res.json(results);
            }
        }
    );
}

const dbQueryPost = async (db, res, query, params) => {
    db.query(
        query,
        params,
        (err, results) => {
            if (err) {
                const errObj = {
                    message: "Error saving to database!",
                    error: err
                }
                res.status(500).json(errObj);
            } else {
                console.log("Loan data obtained successfully!");
                res.json(results);
            }
        }
    );
}

module.exports = { dbQueryGet, dbQueryPost };