SELECT *
FROM
    anza_loans.lending_terms lt
    INNER JOIN anza_loans.confirmed_loans cl ON lt.refinance_debt_id = cl.debt_id
WHERE
    lt.collateral NOT IN ('')
    AND lt.allowed = true
    AND cl.borrower != '0x70997970c51812dc3a010c7d01b50e0d17dc79c8'
ORDER BY collateral ASC;