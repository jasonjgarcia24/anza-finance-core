import axios from 'axios';
import config from '../config.json';

export const insertConfirmedLoans = async (
  debtId,
  borrower,
  lender,
  activeLoanIndex,
  loanStartTime,
  loanEndTime
) => {
  let response;

  try {
    response = await axios.post(
      `http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/insert/confirmed_loans`,
      {
        debtId: debtId.toString(),
        borrower: borrower.toLowerCase(),
        lender: lender.toLowerCase(),
        activeLoanIndex: activeLoanIndex.toString(),
        loanStartTime: loanStartTime.toString(),
        loanEndTime: loanEndTime.toString()
      }
    );
  } catch (err) {
    response = err.response;
  }

  return response;
};
