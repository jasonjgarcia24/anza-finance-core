const dbReadJoin = (app, db) => {
    let query;

    // Leverage Select - Debt All - Unsponsored
    app.get('/api/select/join/unsponsored/:lenderAddress/:borrowerAddress', (req, res) => {
        // lenderAddress should be address(0)    
        const lenderAddress = req.params.lenderAddress;

        // borrowerAddress should be lender
        const borrowerAddress = req.params.borrowerAddress;

        query = `SELECT 
                l.primaryKey,
                l.borrowerAddress,
                l.tokenContractAddress,
                l.tokenId,
                l.ownerAddress,
                l.principal,
                l.fixedInterestRate,
                l.duration,
                d.cid,
                d.debtTokenContractAddress,
                d.debtTokenId,
                d.quantity
                FROM nft.leveraged as l
                LEFT JOIN nft.debt as d
                ON l.primaryKey=d.primaryKey
                WHERE lenderAddress='${lenderAddress}' 
                AND borrowerAddress!='${borrowerAddress}'
                AND (borrowerSigned='N' OR lenderSigned='N')
                ORDER BY l.tokenContractAddress ASC, CAST (l.tokenId AS UNSIGNED) ASC;`;

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });

    // borrowerSigned IS NULL (can be used to fined non leveraged tokens)
    app.get('/api/select/join/borrowerSignedNull/:ownerAddress', (req, res) => {
        const ownerAddress = req.params.ownerAddress;

        query = `SELECT 
                p.primaryKey,
                p.ownerAddress,
                p.tokenContractAddress,
                p.tokenId,
                l.borrowerSigned
                FROM nft.portfolio as p 
                LEFT JOIN nft.leveraged as l
                ON p.primaryKey=l.primaryKey
                WHERE p.ownerAddress='${ownerAddress}'
                AND l.borrowerSigned IS NULL
                ORDER BY p.tokenContractAddress ASC, CAST (p.tokenId AS UNSIGNED) ASC;`

        db.query(
            query,
            (_, result) => { res.send(result); }
        );
    });
}

module.exports = { dbReadJoin };