-- Active: 1681265439276@@127.0.0.1@3306@anza_loans

DROP Table lending_terms;

DROP Table confirmed_loans;

CREATE TABLE
    confirmed_loans (
        debt_id VARCHAR(78) NOT NULL UNIQUE PRIMARY KEY,
        borrower CHAR(42) NOT NULL,
        lender CHAR(42) NOT NULL,
        active_loan_index VARCHAR(78) NOT NULL,
        loan_start_time VARCHAR(20) NOT NULL,
        loan_commit_time VARCHAR(20) NOT NULL,
        loan_end_time VARCHAR(20) NOT NULL
    );

CREATE TABLE
    lending_terms (
        signed_message CHAR(132) NOT NULL UNIQUE PRIMARY KEY,
        packed_contract_terms CHAR(66) NOT NULL,
        borrower CHAR(42) NOT NULL,
        collateral VARCHAR(121) NOT NULL,
        collateral_nonce VARCHAR(78) NOT NULL,
        is_fixed BOOLEAN NOT NULL,
        principal VARCHAR(39) NOT NULL,
        fixed_interest_rate VARCHAR(3) NOT NULL,
        fir_interval VARCHAR(2) NOT NULL,
        grace_period VARCHAR(10) NOT NULL,
        duration VARCHAR(10) NOT NULL,
        commital VARCHAR(3) NOT NULL,
        terms_expiry VARCHAR(10) NOT NULL,
        lender_royalties VARCHAR(3) NOT NULL,
        allowed BOOLEAN NOT NULL DEFAULT true,
        rejected BOOLEAN NOT NULL DEFAULT false,
        debt_id VARCHAR(78) UNIQUE,
        refinance_debt_id VARCHAR(78),
        FOREIGN KEY (debt_id) REFERENCES confirmed_loans (debt_id),
        FOREIGN KEY (refinance_debt_id) REFERENCES confirmed_loans (debt_id)
    );