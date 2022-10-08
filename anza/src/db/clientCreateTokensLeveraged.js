import axios from 'axios';
import config from '../config.json';

export const createTokensLeveraged = (
    primaryKey,
    ownerAddress,
    borrowerAddress,
    tokenContractAddress,
    tokenId,
    lenderAddress,
    principal,
    fixedInterestRate,
    duration,
    borrowerSigned,
    lenderSigned,
) => {    
    axios.post(
      `http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/insert/leveraged`,
      {
        primaryKey: primaryKey,
        ownerAddress: ownerAddress,
        borrowerAddress: borrowerAddress,
        tokenContractAddress: tokenContractAddress,
        tokenId: tokenId,
        lenderAddress: lenderAddress,
        principal: principal,
        fixedInterestRate: fixedInterestRate,
        duration: duration,
        borrowerSigned: borrowerSigned,
        lenderSigned: lenderSigned    
      }
    );
};
