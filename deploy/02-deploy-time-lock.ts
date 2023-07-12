import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { MIN_DELAY } from "../utils/helper-hardhat-config";
import { ethers } from "hardhat";

const deployTimeLock: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    log("Deploying Time Lock...");

    const salt = ethers.utils.keccak256(ethers.utils.randomBytes(32));
    console.log(deployer);

    const timeLockDeploy = await deploy("TimeLock", {
        from: deployer,
        args: [MIN_DELAY, [], []],
        log: true,
        // deterministicDeployment: salt,
    });
    console.log(timeLockDeploy.address);

    const timeLock = await ethers.getContractAt(
        "TimeLock",
        timeLockDeploy.address
    );
    const adminRole = await timeLock.TIMELOCK_ADMIN_ROLE();

    console.log(
        `TimeLock admin: ${await timeLock.hasRole(adminRole, deployer)}`
    );
};

export default deployTimeLock;
