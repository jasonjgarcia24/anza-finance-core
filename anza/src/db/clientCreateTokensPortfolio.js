import axios from 'axios';
import config from '../config.json';

export const clientCreateTokensPortfolio = async (portfolioVals) => {    
    axios.post(
      `http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/insert/portfolio`,
      { portfolioVals: portfolioVals }
    );
};