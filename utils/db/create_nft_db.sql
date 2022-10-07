CREATE DATABASE nft;

CREATE TABLE IF NOT EXISTS nft.leveraged(
    primaryKey VARCHAR(121) NOT NULL,
    ownerAddress VARCHAR(42) NOT NULL,
    borrowerAddress VARCHAR(42) NOT NULL,
    tokenContractAddress VARCHAR(42) NOT NULL,
    tokenId VARCHAR(78) NOT NULL,
    lenderAddress VARCHAR(42),
    principal VARCHAR(78) NOT NULL,
    fixedInterestRate VARCHAR(78) NOT NULL,
    duration VARCHAR(78) NOT NULL,
    borrowerSigned VARCHAR(78) NOT NULL,
    lenderSigned VARCHAR(1) NOT NULL,
    UNIQUE (primaryKey),
    CHECK ((borrowerSigned='Y' OR borrowerSigned='N') AND (lenderSigned='Y' OR lenderSigned='N'))
);

CREATE TABLE IF NOT EXISTS nft.portfolio(
    primaryKey VARCHAR(121),
    ownerAddress VARCHAR(42) NOT NULL,
    tokenContractAddress VARCHAR(42) NOT NULL,
    tokenId VARCHAR(78) NOT NULL,
    leveraged VARCHAR(1),
    UNIQUE (primaryKey)
);
