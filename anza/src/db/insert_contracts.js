import axios from 'axios';
import config from '../config.json';

export const insertContracts = async (
    accountAddress,
    tokenContractAddress,
    tokenId,
    contractAddress=null
) => {    
    axios.post(
      `http://${config.DATABASE.HOST}:${config.SERVER.PORT}/api/insert`,
      {
          accountAddress: accountAddress,
          tokenContractAddress: tokenContractAddress,
          tokenId: tokenId,
          contractAddress: contractAddress
      }
    );
};
