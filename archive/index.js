const express = require('express');
const cors = require('cors');
const router = express.Router();
const { config } = require('./config/config');
const db = require('./config/db');

const app = express();
app.use(cors());
app.use(express.json());

// Route to get all posts
app.get('/api/get', (req, res) => {
  db.query(
    "SELECT * FROM contracts.borrowers",
    (err, result) => {
      if (err) { console.log(err); }
      res.send(result);
    }
  );
});

// Route to get one post
app.get('/api/getFromId/:tokenId', (req, res) => {
  const id = req.params.tokenId;
  db.query(
    "SELECT * FROM contracts.borrowers WHERE tokenId = ?",
    tokenId,
    (err, result) => {
      if (err) { console.log(err); }
      res.send(result);
    }
  );
});

// Route for creating the post
app.post('/api/create', (req, res) => {
  const username = req.body.userName;
  const title = req.body.title;
  const text = req.body.text;

  db.query(
    "INSERT INTO contracts.borrower (accountAddress, tokenContractAddress, tokenId, contractAddress) VALUES (?, ?, ?, ?)",
    [accountAddress, tokenContractAddress, tokenId, contractAddress],
    (err, result) => {
      if (err) { console.log(err); }
      console.log(result);
    }
  );
});

// Route to delete a post
app.delete('/api/delete:tokenId', (req, res) => {
  const id = req.params.tokenId;

  db.query(
    "DELETE FROM contracts.borrowers WHERE tokenId=?",
    tokenId,
    (err, result) => {
      if (err) { console.log(err); }
    }
  );
});

/* GET home page. */
router.get('/borrowing', function(req, res, next) {
  console.log(` --- RES: ${req}`);
  res.render('index', { title: 'Express' });
});

module.exports = router;
