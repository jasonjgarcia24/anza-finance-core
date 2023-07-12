import { ethers, network } from "hardhat";
import { developmentChains } from "../utils/helper-hardhat-config";
import { moveBlocks } from "../utils/move-blocks";
import { VOTING_DELAY, proposalsFile } from "../utils/helper-hardhat-config";
import * as fs from "fs";

export async function propose(
    args: any[],
    functionToCall: string,
    proposalDescription: string
) {
    const governor = await ethers.getContract("AnzaGovernance");

    const collateralVault = await ethers.getContract("CollateralVault");

    const encodedFunctionCall = collateralVault.interface.encodeFunctionData(
        functionToCall,
        args
    );

    console.log(`Encoded function call: ${encodedFunctionCall}`);

    const proposeTx = await governor.propose(
        [collateralVault.address],
        [0],
        [encodedFunctionCall],
        proposalDescription
    );
    const proposeReceipt = await proposeTx.wait(1);

    if (developmentChains.includes(network.name)) {
        await moveBlocks(VOTING_DELAY + 1);
    }

    const proposalId = proposeReceipt.events[0].args.proposalId;

    let proposals = JSON.parse(fs.readFileSync(proposalsFile, "utf8"));
    proposals[network.config.chainId!.toString()].push(proposalId.toString());
    fs.writeFileSync(proposalsFile, JSON.stringify(proposals));

    console.log(`Proposal ID: ${proposalId.toString()}`);
}

async function getAdminRole() {
    const libLoanContractRoles = await ethers.getContract(
        "LibLoanContractRoles"
    );

    const admin_role = await libLoanContractRoles.ADMIN();

    return admin_role;
}

getAdminRole().then((admin_role) => {
    propose(
        [admin_role, "0x0b1928F5EbCFF7d9d2c8d72c608479d27117b14D"],
        "grantRole",
        "Proposal #1: Add admin."
    )
        .then(() => process.exit(0))
        .catch((error) => {
            console.log(error);
            process.exit(1);
        });
});
