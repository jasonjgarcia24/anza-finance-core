require('dotenv').config();
const config = require('./config');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const express = require('express');
const app = express();

const { dbCreatePortfolio: createPortfolio } = require('./crud/portfolio/dbCreatePortfolio');
const { dbReadPortfolio: readPortfolio } = require('./crud/portfolio/dbReadPortfolio');
const { dbUpdatePortfolio: updatePortfolio } = require('./crud/portfolio/dbUpdatePortfolio');
const { dbCreateLeveraged: createLeveraged } = require('./crud/leveraged/dbCreateLeveraged');
const { dbReadLeveraged: readLeveraged } = require('./crud/leveraged/dbReadLeveraged');
const { dbUpdateLeveraged: updateLeveraged } = require('./crud/leveraged/dbUpdateLeveraged');
const { dbReadJoin: readJoin } = require('./crud/join/dbReadJoin');
const { dbCreateDebt: createDebt } = require('./crud/debt/dbCreateDebt');

const {
    dbSelectProposedLoanTerms: selectProposedLoanTerms,
    dbSelectAtProposedLoanTerms: selectAtProposedLoanTerms,
    dbSelectAvailableLoanTerms: selectAvailableLoanTerms,
    dbSelectApprovedLoanTerms: selectApprovedLoanTerms
} = require('./crud/debt/server_selectLoanTerms');
const { dbInsertProposedLoanTerms: insertLoanTerms } = require('./crud/debt/server_insertProposedLoanTerms');

const db = mysql.createPool({
    host: config.DATABASE.HOST,
    port: config.DATABASE.PORT,
    user: config.DATABASE.USER,
    password: process.env.ANZA_DB_PASSWORD,
    database: config.DATABASE.DATABASE
});

// test the connection
db.getConnection((err, connection) => {
    if (err) throw err;
    console.log('Connected to MySQL Server!');
    connection.release();
});

app.use(cors());
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));

// nft.leveraged CRUD
createLeveraged(app, db);
readLeveraged(app, db);
updateLeveraged(app, db);

// nft.portfolio CRUD
createPortfolio(app, db);
readPortfolio(app, db);
updatePortfolio(app, db);

// nft.debt CRUD
selectProposedLoanTerms(app, db);
selectAtProposedLoanTerms(app, db);
selectAvailableLoanTerms(app, db);
selectApprovedLoanTerms(app, db);
insertLoanTerms(app, db);
createDebt(app, db);

// nft.leveraged and nft.portfolio RUD
readJoin(app, db);

app.listen(config.SERVER.PORT, () => {
    console.log(`Running on port ${config.SERVER.PORT}`);
});
