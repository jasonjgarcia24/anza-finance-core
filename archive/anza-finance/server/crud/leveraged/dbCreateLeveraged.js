let query;

const dbCreateLeveraged = (app, db) => {
    app.post('/api/insert/leveraged', (req, res) => {
        const primaryKey = req.body.primaryKey;
        const ownerAddress = req.body.ownerAddress;
        const borrowerAddress = req.body.borrowerAddress;
        const tokenContractAddress = req.body.tokenContractAddress;
        const tokenId = req.body.tokenId;
        const lenderAddress = req.body.lenderAddress;
        const principal = req.body.principal;
        const fixedInterestRate = req.body.fixedInterestRate;
        const duration = req.body.duration;
        const borrowerSigned = req.body.borrowerSigned;
        const lenderSigned = req.body.lenderSigned;

        query = `INSERT INTO nft.leveraged(
            primaryKey,
            ownerAddress,
            borrowerAddress,
            tokenContractAddress,
            tokenId,
            lenderAddress,
            principal,
            fixedInterestRate,
            duration,
            borrowerSigned,
            lenderSigned
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);`;

        db.query(
            query,
            [
                primaryKey,
                ownerAddress, 
                borrowerAddress, 
                tokenContractAddress, 
                tokenId, 
                lenderAddress, 
                principal, 
                fixedInterestRate, 
                duration, 
                borrowerSigned, 
                lenderSigned
            ],
            (err, _) => { console.log(err); }
        );
    });
}

module.exports = { dbCreateLeveraged };