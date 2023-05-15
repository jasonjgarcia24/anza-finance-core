import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, network } from "hardhat";

const deployGovernanceToken: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    log("Deploying Goverance Token...");

    const salt = ethers.utils.keccak256(ethers.utils.randomBytes(32));

    const governanceToken = await deploy("AnzaGovernanceToken", {
        from: deployer,
        args: [],
        log: true,
        // deterministicDeployment: salt,
    });

    log(`Deployed goverance token to address ${governanceToken.address}`);

    await delegate(governanceToken.address, deployer);
    log("Delegated!");
};

const delegate = async (
    governanceTokenAddress: string,
    delegatedAccount: string
) => {
    const governanceToken = await ethers.getContractAt(
        "AnzaGovernanceToken",
        governanceTokenAddress
    );
    console.log(`Delegated account: ${delegatedAccount}`);

    const tx = await governanceToken.delegate(delegatedAccount);
    await tx.wait(1);

    console.log(
        `Checkpoints ${await governanceToken.numCheckpoints(delegatedAccount)}`
    );
};

export default deployGovernanceToken;
