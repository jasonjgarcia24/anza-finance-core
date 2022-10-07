import axios from 'axios';
import config from '../config.json';

export const clientUpdatePortfolioLeveragedStatus = async (primaryKey, leveragedStatus) => {   
  console.log('updating leveraged status')

  axios.post(
      `http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/update/portfolio/leveraged`,
      { primaryKey: primaryKey, leveragedStatus: leveragedStatus }
    );
};