import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const deployLoanContracts: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const timeLock = await ethers.getContract("TimeLock", deployer);
    const anzaGovernance = await ethers.getContract("AnzaGovernance", deployer);

    log("Deploying Anza smart contracts...");

    const salt = ethers.utils.keccak256(ethers.utils.randomBytes(32));

    const libLoanContractRolesDeploy = await deploy("LibLoanContractRoles", {
        from: deployer,
        args: [],
        log: true,
    });
    const libLoanContractRoles = await ethers.getContractAt(
        "LibLoanContractRoles",
        libLoanContractRolesDeploy.address
    );

    const loanContractInterestDeploy = await deploy("LibLoanContractInterest", {
        from: deployer,
        args: [],
        log: true,
        // deterministicDeployment: salt,
    });
    const loanContractInterest = await ethers.getContractAt(
        "LibLoanContractInterest",
        loanContractInterestDeploy.address
    );

    const anzaTokenDeploy = await deploy("AnzaToken", {
        from: deployer,
        args: [],
        log: true,
        // deterministicDeployment: salt,
    });
    const anzaToken = await ethers.getContractAt(
        "AnzaToken",
        anzaTokenDeploy.address
    );

    const loanContractDeploy = await deploy("LoanContract", {
        from: deployer,
        args: [],
        libraries: {
            LibLoanContractInterest: loanContractInterest.address,
        },
        log: true,
        // deterministicDeployment: salt,
    });
    const loanContract = await ethers.getContractAt(
        "LoanContract",
        loanContractDeploy.address
    );

    const loanTreasureyDeploy = await deploy("LoanTreasurey", {
        from: deployer,
        args: [],
        libraries: {
            LibLoanContractInterest: loanContractInterest.address,
        },
        log: true,
        // deterministicDeployment: salt,
    });
    const loanTreasurey = await ethers.getContractAt(
        "LoanTreasurey",
        loanTreasureyDeploy.address
    );

    const collateralVaultDeploy = await deploy("CollateralVault", {
        from: deployer,
        args: [anzaToken.address],
        log: true,
        // deterministicDeployment: salt,
    });
    const collateralVault = await ethers.getContractAt(
        "CollateralVault",
        collateralVaultDeploy.address
    );

    log("All contracts deployed :)");

    log("Setting up Anza roles...");

    const ADMIN_ROLE = await libLoanContractRoles.ADMIN();
    const LOAN_CONTRACT_ROLE = await libLoanContractRoles.LOAN_CONTRACT();
    const TREASURER_ROLE = await libLoanContractRoles.TREASURER();
    const COLLECTOR_ROLE = await libLoanContractRoles.COLLECTOR();
    const DEBT_STOREFRONT_ROLE = await libLoanContractRoles.DEBT_MARKET();
    let tx: any;

    // AnzaToken roles
    tx = await anzaToken.grantRole(LOAN_CONTRACT_ROLE, loanContract.address);
    await tx.wait(1);

    tx = await anzaToken.grantRole(TREASURER_ROLE, loanTreasurey.address);
    await tx.wait(1);

    // LoanContract roles
    tx = await loanContract.setAnzaToken(anzaToken.address);
    await tx.wait(1);

    tx = await loanContract.setLoanTreasurer(loanTreasurey.address);
    await tx.wait(1);

    tx = await loanContract.setCollateralVault(collateralVault.address);
    await tx.wait(1);

    // LoanTreasurey roles
    tx = await loanTreasurey.setAnzaToken(anzaToken.address);
    await tx.wait(1);

    tx = await loanTreasurey.setLoanContract(loanContract.address);
    await tx.wait(1);

    tx = await loanTreasurey.setCollateralVault(collateralVault.address);
    await tx.wait(1);

    // CollateralVault roles
    tx = await collateralVault.setLoanContract(loanContract.address);
    await tx.wait(1);

    tx = await collateralVault.grantRole(TREASURER_ROLE, loanTreasurey.address);
    await tx.wait(1);

    log("Transferring admin roles to DAO...");

    // AnzaToken
    tx = await anzaToken.grantRole(ADMIN_ROLE, timeLock.address);
    await tx.wait(1);

    tx = await anzaToken.renounceRole(ADMIN_ROLE, deployer);
    await tx.wait(1);

    // LoanContract
    tx = await loanContract.grantRole(ADMIN_ROLE, timeLock.address);
    await tx.wait(1);

    tx = await loanContract.renounceRole(ADMIN_ROLE, deployer);
    await tx.wait(1);

    // LoanTreasurey
    tx = await loanTreasurey.grantRole(ADMIN_ROLE, timeLock.address);
    await tx.wait(1);

    tx = await loanTreasurey.renounceRole(ADMIN_ROLE, deployer);
    await tx.wait(1);

    // CollateralVault
    tx = await collateralVault.grantRole(ADMIN_ROLE, timeLock.address);
    await tx.wait(1);

    tx = await collateralVault.renounceRole(ADMIN_ROLE, deployer);
    await tx.wait(1);

    log("DAO ownership transfer complete!!!");
};

export default deployLoanContracts;
