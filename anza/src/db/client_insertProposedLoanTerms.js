import axios from 'axios';
import config from '../config.json';

export const insertProposedLoanTerms = async (
  signedMessage,
  packedContractTerms,
  collateralAddress,
  collateralId,
  collateralNonce,
  contractTerms
) => {
  let response;

  try {
    response = await axios.post(
      `http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/insert/lending_terms`,
      {
        signedMessage: signedMessage,
        packedContractTerms: packedContractTerms,
        collateral: `${collateralAddress.toLowerCase()}_${collateralId}`,
        collateralNonce: collateralNonce.toString(),
        isFixed: contractTerms["is_fixed"].toString(),
        principal: contractTerms["principal"].toString(),
        fixedInterestRate: contractTerms["fixed_interest_rate"].toString(),
        firInterval: contractTerms["fir_interval"].toString(),
        gracePeriod: contractTerms["grace_period"].toString(),
        duration: contractTerms["duration"].toString(),
        commital: contractTerms["commital"].toString(),
        termsExpiry: contractTerms["terms_expiry"].toString(),
        lenderRoyalties: contractTerms["lender_royalties"].toString()
      }
    );
  } catch (err) {
    response = err.response;
  }

  return response;
};
