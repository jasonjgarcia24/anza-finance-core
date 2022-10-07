CREATE TABLE IF NOT EXISTS nft.leveraged(
    ownerAddress VARCHAR(42) NOT NULL,
    borrowerAddress VARCHAR(42) NOT NULL,
    tokenContractAddress VARCHAR(42) NOT NULL,
    tokenId VARCHAR(78) NOT NULL,
    lenderAddress VARCHAR(42),
    principal VARCHAR(78) NOT NULL,
    fixedInterestRate VARCHAR(78) NOT NULL,
    duration VARCHAR(78) NOT NULL,
    borrowerSigned VARCHAR(78) NOT NULL,
    lenderSigned VARCHAR(78) NOT NULL
);