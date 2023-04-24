-- Active: 1681265439276@@127.0.0.1@3306@anza_loans

SELECT *
FROM
    anza_loans.confirmed_loans cl
    INNER JOIN anza_loans.lending_terms lt ON cl.debt_id = lt.debt_id
WHERE
    cl.borrower = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
    AND UNIX_TIMESTAMP(
        FROM_UNIXTIME(cl.loan_commit_time)
    ) < 1682136122
ORDER BY cl.debt_id ASC;