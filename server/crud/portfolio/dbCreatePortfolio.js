let query;

const dbCreatePortfolio = (app, db) => {
    app.post('/api/insert/portfolio', (req, res) => {
        const portfolioVals = req.body.portfolioVals;

        query = `INSERT INTO nft.portfolio (
            primaryKey,
            ownerAddress, 
            tokenContractAddress, 
            tokenId,
            leveraged
        ) VALUES`;

        portfolioVals.forEach((_) => { query += '(?),'; });
        query = query.replace(/(^,)|(,$)/g, "") + ';';

        db.query(query, portfolioVals, (err, _) => {
            if (!!err && err.code === 'ER_DUP_ENTRY') {
                console.log('Duplicate entries ignored.')
            }
        });
    });
}

module.exports = { dbCreatePortfolio };