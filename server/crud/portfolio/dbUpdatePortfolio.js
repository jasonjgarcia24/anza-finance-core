let query;

const dbUpdatePortfolio = (app, db) => {
    app.post('/api/update/portfolio/leveraged', (req, res) => {
        const primaryKey = req.body.primaryKey;
        const leveragedStatus = req.body.leveragedStatus;

        query = `UPDATE nft.portfolio
            SET leveraged=?
            WHERE primaryKey=?;`

        db.query(
            query,
            [leveragedStatus, primaryKey],
            (err, _) => { console.log(err); }
        );
    });
}

module.exports = { dbUpdatePortfolio };