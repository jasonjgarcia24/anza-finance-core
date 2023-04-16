const dbReadPortfolio = (app, db) => {
    let query;

    // Primary key - Account
    app.get('/api/select/portfolio/key/:ownerAddress', (req, res) => {
        const ownerAddress = req.params.ownerAddress;

        query = `SELECT primaryKey FROM nft.portfolio WHERE ownerAddress='${ownerAddress}';`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });

    // All - Account
    app.get('/api/select/portfolio/:ownerAddress', (req, res) => {
        const ownerAddress = req.params.ownerAddress;

        query = `SELECT * FROM nft.portfolio WHERE ownerAddress='${ownerAddress}';`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });

    // All - Account - Leveraged status
    app.get('/api/select/portfolio/:ownerAddress/:leveragedStatus', (req, res) => {
        const ownerAddress = req.params.ownerAddress;
        const leveragedStatus = req.params.leveragedStatus;

        query = `SELECT * FROM nft.portfolio WHERE ownerAddress='${ownerAddress}' AND leveraged='${leveragedStatus}';`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });

    // Preview - Account - Leveraged status
    app.get('/api/select/portfolio/:ownerAddress/:leveragedStatus', (req, res) => {
        const ownerAddress = req.params.ownerAddress;
        const leveragedStatus = req.params.leveragedStatus;

        query = `SELECT 
                ownerAddress,
                tokenContractAddress,
                tokenId,
                leveraged
                FROM nft.portfolio 
                WHERE ownerAddress='${ownerAddress}' 
                AND leveraged='${leveragedStatus}'`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
}

module.exports = { dbReadPortfolio };