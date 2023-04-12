-- Active: 1681265439276@@127.0.0.1@3306@anza_loans

CREATE TABLE
    lending_terms (
        cid VARCHAR(150) PRIMARY KEY,
        debtId VARCHAR(64),
        firInterval INT UNSIGNED NOT NULL,
        fixedInterestRate INT UNSIGNED NOT NULL,
        isDirect BOOLEAN NOT NULL,
        commital INT NOT NULL,
        principal VARCHAR(32) NOT NULL,
        gracePeriod BIGINT UNSIGNED NOT NULL,
        duration BIGINT UNSIGNED NOT NULL,
        termsExpiry BIGINT UNSIGNED NOT NULL,
        lenderRoyalties INT UNSIGNED NOT NULL,
        FOREIGN KEY (debtId) REFERENCES confirmed_loans (debtId)
    );