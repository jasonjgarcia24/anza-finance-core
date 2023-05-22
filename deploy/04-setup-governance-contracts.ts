import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const setupGovernanceContracts: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { getNamedAccounts, deployments } = hre;
    const { log } = deployments;
    const { deployer } = await getNamedAccounts();
    const timeLock = await ethers.getContract("TimeLock", deployer);
    const anzaGovernance = await ethers.getContract("AnzaGovernance", deployer);

    log("Setting up roles...");

    const proposerRole = await timeLock.PROPOSER_ROLE();
    const executorRole = await timeLock.EXECUTOR_ROLE();
    const adminRole = await timeLock.TIMELOCK_ADMIN_ROLE();

    const proposerTx = await timeLock.grantRole(
        proposerRole,
        anzaGovernance.address
    );
    await proposerTx.wait(1);

    const executorTx = await timeLock.grantRole(
        executorRole,
        ethers.constants.AddressZero
    );
    await executorTx.wait(1);

    const revokeTx = await timeLock.revokeRole(adminRole, deployer);
    await revokeTx.wait(1);

    log("Governance roles set!");
};

export default setupGovernanceContracts;
