const dbReadJoin = (app, db) => {      
    let query;
    
    // // All - Not signed
    // app.get('/api/select/join/eitherUnsigned', (req, res) => {
    //     query = `SELECT 
    //         p.primaryKey,
    //         p.ownerAddress,
    //         p.tokenContractAddress,
    //         p.tokenId,
    //         l.borrowerAddress,
    //         l.lenderAddress,
    //         l.principal,
    //         l.fixedInterestRate,
    //         l.duration,
    //         l.borrowerSigned,
    //         l.lenderSigned
    //         FROM nft.portfolio as p 
    //         LEFT JOIN nft.leveraged as l
    //         ON p.primaryKey=l.primaryKey
    //         WHERE p.ownerAddress='${accountAddress}'
    //         AND (
    //             l.borrowerSigned='N' 
    //             OR l.lenderSigned='N' 
    //             OR l.borrowerSigned IS NULL 
    //             OR l.lenderSigned IS NULL
    //         );`

    //     db.query(
    //         query,
    //         (_, result) => { res.send(result); }
    //     );
    // });

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