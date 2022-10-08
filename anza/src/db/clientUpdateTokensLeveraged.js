import axios from 'axios';
import config from '../config.json';

export const clientUpdateLeveragedLenderSigned = async (primaryKey, lenderAddress, lenderSigned) => {   
  console.log('updating leveraged status')

  axios.post(
      `http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/update/leveraged/lender`,
      { primaryKey: primaryKey, lenderAddress: lenderAddress, lenderSigned: lenderSigned }
    );
};