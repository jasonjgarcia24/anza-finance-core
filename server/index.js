require('dotenv').config();
const config = require('./config');
const cors = require('cors');
const mysql = require('mysql');
const express = require('express');
const bodyParser = require('body-parser');
const app = express();

const { dbCreatePortfolio: createPortfolio } = require('./crud/portfolio/dbCreatePortfolio');
const { dbReadPortfolio: readPortfolio } = require('./crud/portfolio/dbReadPortfolio');
const { dbUpdatePortfolio: updatePortfolio } = require('./crud/portfolio/dbUpdatePortfolio');
const { dbCreateLeveraged: createLeveraged } = require('./crud/leveraged/dbCreateLeveraged');
const { dbReadLeveraged: readLeveraged } = require('./crud/leveraged/dbReadLeveraged');
const { dbUpdateLeveraged: updateLeveraged } = require('./crud/leveraged/dbUpdateLeveraged');
const { dbReadJoin: readJoin } = require('./crud/join/dbReadJoin');

const db = mysql.createPool({
    host: config.DATABASE.HOST,
    user: config.DATABASE.USER,
    password: process.env.DB_PASSWORD,
    database: 'nft'
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

// both RUD
readJoin(app, db);

app.listen(config.SERVER.PORT, () => {
    console.log(`Running on port ${config.SERVER.PORT}`);
});