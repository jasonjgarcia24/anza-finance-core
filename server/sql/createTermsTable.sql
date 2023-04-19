-- Active: 1681265439276@@127.0.0.1@3306@anza_loans

CREATE TABLE
    lending_terms (
        signed_message CHAR(132) NOT NULL UNIQUE PRIMARY KEY,
        packed_contract_terms CHAR(66) NOT NULL,
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
        debt_id VARCHAR(78) NULL UNIQUE,
        FOREIGN KEY (debt_id) REFERENCES confirmed_loans (debt_id)
    );