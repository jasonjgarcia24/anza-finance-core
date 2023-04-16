import { ethers } from "ethers";
import config from "../config.json";
import { hexlify } from "@ethersproject/bytes";
import abi_LoanContract from '../artifacts/LoanContract.sol/LoanContract.json';
import abi_LibLoanContractSigning from '../artifacts/LibLoanContract.sol/LibLoanContractSigning.json';


export const getSignedMessage = async (signer, chainId, contractTerms, tokenAddress, tokenId) => {
    const LoanContract = new ethers.Contract(
        config[chainId].LoanContract,
        abi_LoanContract.abi,
        signer
    );

    const LoanSigningLib = new ethers.Contract(
        config[chainId].LibLoanContractSigning,
        abi_LibLoanContractSigning.abi,
        signer
    );

    const packedContractTerms = await LoanSigningLib.createContractTerms(
        contractTerms["fir_interval"],
        contractTerms["fixed_interest_rate"],
        contractTerms["is_fixed"],
        contractTerms["commital"],
        contractTerms["grace_period"],
        contractTerms["duration"],
        contractTerms["terms_expiry"],
        contractTerms["lender_royalties"]
    );

    const collateralNonce = await LoanContract.getCollateralNonce(
        tokenAddress,
        tokenId
    );

    console.log(ethers.utils.parseEther(contractTerms["principal"].toString(), "ether"));

    const hashedMessage = await LoanSigningLib.hashMessage(
        ethers.utils.parseEther(contractTerms["principal"].toString(), "ether"),
        packedContractTerms,
        tokenAddress,
        tokenId,
        collateralNonce
    );

    const signedMessage = await signer.provider.send(
        "personal_sign",
        [
            hexlify(hashedMessage),
            (await signer.getAddress()).toLowerCase()
        ]
    );

    return {
        packedContractTerms: packedContractTerms,
        collateralNonce: collateralNonce,
        hashedMessage: hashedMessage,
        signedMessage: signedMessage
    };
}

export const getContractTerms = (tokenAddress, tokenId) => {
    // Get selected loan terms
    const contractTerms = {};

    const termNames = [
        "fir_interval",
        "fixed_interest_rate",
        "is_fixed",
        "commital",
        "principal",
        "grace_period",
        "duration",
        "terms_expiry",
        "lender_royalties"
    ];

    termNames.map(term => {
        const id = `${term}-${tokenAddress}-${tokenId}-terms`;
        contractTerms[term] = document.getElementById(id).value
        contractTerms[term] = term !== "is_fixed" ? contractTerms[term].toString() : contractTerms[term] === "Y" ? "1" : "0";
        contractTerms[term] = term !== "principal" ? ethers.BigNumber.from(contractTerms[term]) : ethers.utils.parseEther(contractTerms[term]);
    });

    return contractTerms;
}