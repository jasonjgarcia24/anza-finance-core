import axios from 'axios';
import config from '../config.json';

// 0.1.0 :: Inserts the lender's newly confirmed sponsored loan.
export const insertConfirmedLoans = async (
  debtId,
  borrower,
  lender,
  activeLoanIndex,
  loanStartTime,
  loanCommitTime,
  loanEndTime
) => {
  let response;
  console.log(loanStartTime);
  console.log(loanCommitTime);

  try {
    response = await axios.post(
      `http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/insert/confirmed_loans`,
      {
        debtId: debtId.toString(),
        borrower: borrower.toLowerCase(),
        lender: lender.toLowerCase(),
        activeLoanIndex: activeLoanIndex.toString(),
        loanStartTime: loanStartTime.toString(),
        loanCommitTime: loanCommitTime.toString(),
        loanEndTime: loanEndTime.toString()
      }
    );
  } catch (err) {
    response = err.response;
  }

  return response;
};
