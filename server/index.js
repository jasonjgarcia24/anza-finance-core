require('dotenv').config();
const config = require('./config');
const cors = require('cors');
const mysql = require('mysql');
const express = require('express');
const bodyParser = require('body-parser');
const app = express();

const db = mysql.createPool({
    host: config.DATABASE.HOST,
    user: config.DATABASE.USER,
    password: process.env.DB_PASSWORD,
    database: 'contracts'
});

app.use(cors());
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));

let query;

app.get('/api/select/:accountAddress', (req, res) => {
    const accountAddress = req.params.accountAddress;
    console.log(` --- --- account: ${accountAddress}`)

    query = `SELECT * FROM contracts.borrowers WHERE accountAddress = '${accountAddress}';`,
    db.query(
        query,
        (err, result) => { res.send(result); }
    );
});

app.post('/api/insert', (req, res) => {
    const accountAddress = req.body.accountAddress;
    const tokenContractAddress = req.body.tokenContractAddress;
    const tokenId = req.body.tokenId;
    const contractAddress = req.body.contractAddress;

    query = "INSERT INTO contracts.borrowers(accountAddress, tokenContractAddress, tokenId, contractAddress) VALUES (?, ?, ?, ?);"
    db.query(
        query,
        [accountAddress, tokenContractAddress, tokenId, contractAddress],
        (err, result) => { console.log(err); }
    );
});


app.listen(config.SERVER.PORT, () => {
    console.log(`Running on port ${config.SERVER.PORT}`);
});