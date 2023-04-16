CREATE DATABASE contracts;

CREATE TABLE
    IF NOT EXISTS contracts.borrowers(
        accountAddress VARCHAR(42) NOT NULL,
        tokenContractAddress VARCHAR(42) NOT NULL,
        tokenId VARCHAR(78) NOT NULL,
        contractAddress VARCHAR(42)
    );