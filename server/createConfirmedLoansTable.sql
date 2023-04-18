-- Active: 1681265439276@@127.0.0.1@3306@anza_loans

CREATE TABLE
    confirmed_loans (
        debt_id VARCHAR(78) NOT NULL UNIQUE PRIMARY KEY,
        borrower CHAR(42) NOT NULL,
        lender CHAR(42) NOT NULL,
        active_loan_index VARCHAR(78) NOT NULL,
        loan_start_time VARCHAR(20) NOT NULL,
        loan_end_time VARCHAR(20) NOT NULL
    );