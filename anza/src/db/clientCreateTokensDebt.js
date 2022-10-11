import axios from 'axios';
import config from '../config.json';

export const createTokensDebt = (
  primaryKey,
  cid,
  debtTokenContractAddress,
  debtTokenId,
  quantity
) => {    
    axios.post(
      `http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/insert/debt`,
      { 
        primaryKey: primaryKey,
        cid: cid,
        debtTokenContractAddress: debtTokenContractAddress,
        debtTokenId: debtTokenId,
        quantity: quantity
      }
    );
};
