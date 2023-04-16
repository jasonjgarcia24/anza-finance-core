let query;

const dbCreateDebt = (app, db) => {
    app.post('/api/insert/debt', (req, res) => {
        const primaryKey = req.body.primaryKey;
        const cid = req.body.cid;
        const debtTokenContractAddress = req.body.debtTokenContractAddress;
        const debtTokenId = req.body.debtTokenId;
        const quantity = req.body.quantity;

        query = `INSERT INTO nft.debt(
                primaryKey,
                cid,
                debtTokenContractAddress,
                debtTokenId,
                quantity
            ) VALUES (?, ?, ?, ?, ?);`;

        db.query(
            query,
            [
                primaryKey,
                cid,
                debtTokenContractAddress,
                debtTokenId,
                quantity
            ],
            (err, _) => { console.log(err); }
        );
    });
}

module.exports = { dbCreateDebt };