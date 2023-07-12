import axios from 'axios';
import config from '../config.json';

// 0.0.0 :: Inserts the borrower's newly proposed loans.
export const insertProposedLoanTerms = async (
  signedMessage,
  packedContractTerms,
  borrower,
  collateralAddress,
  collateralId,
  collateralNonce,
  contractTerms,
  refinanceDebtId
) => {
  let response;

  console.log(refinanceDebtId);

  try {
    response = await axios.post(
      `http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/insert/lending_terms`,
      {
        signedMessage: signedMessage,
        packedContractTerms: packedContractTerms,
        borrower: borrower.toLowerCase(),
        collateral: `${collateralAddress.toLowerCase()}_${collateralId.padStart(78, "0")}`,
        collateralNonce: collateralNonce.toString(),
        isFixed: contractTerms["is_fixed"].toString(),
        principal: contractTerms["principal"].toString(),
        fixedInterestRate: contractTerms["fixed_interest_rate"].toString(),
        firInterval: contractTerms["fir_interval"].toString(),
        gracePeriod: contractTerms["grace_period"].toString(),
        duration: contractTerms["duration"].toString(),
        commital: contractTerms["commital"].toString(),
        termsExpiry: contractTerms["terms_expiry"].toString(),
        lenderRoyalties: contractTerms["lender_royalties"].toString(),
        refinanceDebtId: refinanceDebtId ? refinanceDebtId.toString() : null
      }
    );
  } catch (err) {
    response = err.response;
  }

  return response;
};
