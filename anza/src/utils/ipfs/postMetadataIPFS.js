import { create } from 'ipfs-core';
import config from '../../config.json';

export const postMetadataIPFS = async (metadata) => {
    const ipfs = await create({
        protocol: 'http',
        host: 'localhost',
        port: config.IPFS.Addresses.API_PORT
    });

    const { cid } = await ipfs.add(JSON.stringify(metadata));

    return cid.toString();
}
