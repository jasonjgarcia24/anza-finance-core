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
    app.get('/api/select/leveraged/all/borrower/:accountAddress', (req, res) => {
        const accountAddress = req.params.accountAddress;
        console.log(accountAddress)
    
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
    
    // All - Lender - Unsigned
    app.get('/api/select/leveraged/all/lender/unsigned/:lenderAddress', (req, res) => {
        const lenderAddress = req.params.lenderAddress;
        console.log(lenderAddress)
    
        query = `SELECT 
            *
            FROM nft.leveraged 
            WHERE lenderAddress='${lenderAddress}' 
            AND (borrowerSigned='N' OR lenderSigned='N');`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
    
    // All - Lender - Signed
    app.get('/api/select/leveraged/all/lender/signed/:lenderAddress', (req, res) => {
        const lenderAddress = req.params.lenderAddress;
        console.log(lenderAddress)
    
        query = `SELECT 
            *
            FROM nft.leveraged 
            WHERE lenderAddress='${lenderAddress}' 
            AND (borrowerSigned='Y' AND lenderSigned='Y');`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
    
    // All - Lender
    app.get('/api/select/leveraged/all/:lenderAddress', (req, res) => {
        const lenderAddress = req.params.lenderAddress;
        console.log(lenderAddress)
    
        query = `SELECT 
            *
            FROM nft.leveraged 
            WHERE lenderAddress='${lenderAddress}';`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
    
    // LoanContract - Principal - No Sponsor
    app.get('/api/select/leveraged/loancontract/:tokenContractAddress/:tokenId', (req, res) => {
        const primaryKey = `${req.params.tokenContractAddress}_${req.params.tokenId}`;
    
        query = `SELECT 
            ownerAddress,
            principal
            FROM nft.leveraged 
            WHERE primaryKey='${primaryKey}'
            AND (borrowerSigned='N' OR lenderSigned='N');`;

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