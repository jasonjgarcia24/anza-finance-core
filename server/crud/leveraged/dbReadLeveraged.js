const dbReadLeveraged = (app, db) => {      
    let query;

    // Account
    app.get('/api/select/leveraged/:accountAddress', (req, res) => {
        const accountAddress = req.params.accountAddress;
    
        query = `SELECT 
            ownerAddress,
            tokenContractAddress,
            tokenId
            FROM nft.leveraged
            WHERE borrowerAddress='${accountAddress}'`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
    
    // All - Account
    app.get('/api/select/leveraged/all/:accountAddress', (req, res) => {
        const accountAddress = req.params.accountAddress;
    
        query = `SELECT 
            *
            FROM nft.leveraged 
            WHERE borrowerAddress='${accountAddress}' AND
            (borrowerSigned='N' OR lenderSigned='N');`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
    
    // Preview - Account
    app.get('/api/select/leveraged/preview/:accountAddress', (req, res) => {
        const accountAddress = req.params.accountAddress;
    
        query = `SELECT 
            ownerAddress,
            tokenContractAddress,
            tokenId 
            FROM nft.leveraged 
            WHERE borrowerAddress='${accountAddress}' AND
            (borrowerSigned='N' OR lenderSigned='N');`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
    
    // Preview - Unsigned - Account
    app.get('/api/select/leveraged/preview/unsigned/:accountAddress', (req, res) => {
        const accountAddress = req.params.accountAddress;
    
        query = `SELECT 
            ownerAddress,
            tokenContractAddress,
            tokenId
            FROM nft.leveraged 
            WHERE borrowerAddress='${accountAddress}' AND
            (borrowerSigned='N' OR lenderSigned='N');`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
}

module.exports = { dbReadLeveraged };