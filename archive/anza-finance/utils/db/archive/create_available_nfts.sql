CREATE TABLE IF NOT EXISTS nft.available(
    owner VARCHAR(42) NOT NULL,
    tokenContractAddress VARCHAR(42) NOT NULL,
    tokenId VARCHAR(78) NOT NULL
);