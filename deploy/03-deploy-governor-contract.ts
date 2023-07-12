import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { VOTING_PERIOD, VOTING_DELAY } from "../utils/helper-hardhat-config";
import { ethers } from "hardhat";

const deployGovernorContract: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log, get } = deployments;
    const { deployer } = await getNamedAccounts();
    const governanceToken = await get("AnzaGovernanceToken");
    const timeLock = await get("TimeLock");
    log("Deploying Governor Contract...");

    const salt = ethers.utils.keccak256(ethers.utils.randomBytes(32));

    const anzaGovernance = await deploy("AnzaGovernance", {
        from: deployer,
        args: [
            governanceToken.address,
            timeLock.address,
            VOTING_PERIOD,
            VOTING_DELAY,
        ],
        log: true,
        // deterministicDeployment: salt,
    });
};

export default deployGovernorContract;
