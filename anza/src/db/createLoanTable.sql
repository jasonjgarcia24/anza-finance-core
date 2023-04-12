-- Active: 1681265439276@@127.0.0.1@3306@anza_loans

CREATE TABLE
    confirmed_loans (
        debtId CHAR(64) PRIMARY KEY,
        borrower CHAR(42) NOT NULL,
        lender CHAR(42) NOT NULL,
        loanCollateralIndex VARCHAR(64) NOT NULL,
        loanStartTime BIGINT UNSIGNED,
        loanEndTime BIGINT UNSIGNED,
        loanTerms CHAR(32)
    );