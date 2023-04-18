require('dotenv').config();
const config = require('./config');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const express = require('express');
const app = express();

const {
    dbSelectProposedLendingTerms,
    dbSelectAtProposedLendingTerms,
    dbSelectAvailableLendingTerms,
    dbSelectApprovedLendingTerms
} = require('./crud/debt/server_selectLendingTerms');
const { dbInsertProposedLendingTerms } = require('./crud/debt/server_insertLendingTerms');
const { dbInsertConfirmedLoans } = require('./crud/debt/server_insertConfirmedLoans');
const {
    dbUpdateApprovedLendingTerms,
    dbUpdateUnallowedCollateralLendingTerms
} = require('./crud/debt/server_updateLendingTerms');

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

// Create
dbInsertProposedLendingTerms(app, db);
dbInsertConfirmedLoans(app, db);

// Read
dbSelectProposedLendingTerms(app, db);
dbSelectAtProposedLendingTerms(app, db);
dbSelectAvailableLendingTerms(app, db);
dbSelectApprovedLendingTerms(app, db);

// Update
dbUpdateApprovedLendingTerms(app, db);
dbUpdateUnallowedCollateralLendingTerms(app, db);

app.listen(config.SERVER.PORT, () => {
    console.log(`Running on port ${config.SERVER.PORT}`);
});
