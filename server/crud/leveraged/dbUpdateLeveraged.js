let query;

const dbUpdateLeveraged = (app, db) => {
    app.post('/api/update/leveraged/lender', (req, res) => {
        const primaryKey = req.body.primaryKey;
        const lenderAddress = req.body.lenderAddress;
        const lenderSigned = req.body.lenderSigned;
        console.log(primaryKey)

        query = `UPDATE nft.leveraged
                SET lenderAddress=?, lenderSigned=?
                WHERE primaryKey=?;`

        db.query(
            query,
            [lenderAddress, lenderSigned, primaryKey],
            (err, _) => { console.log(err); }
        );
    });
}

module.exports = { dbUpdateLeveraged };