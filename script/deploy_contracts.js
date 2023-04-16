const { ethers } = require("ethers");
const { assert } = require('chai');
require('dotenv').config();

const artifact_AnzaToken = require('../anza/src/artifacts/AnzaToken.sol/AnzaToken.json');
const artifact_LoanContract = require('../anza/src/artifacts/LoanContract.sol/LoanContract.json');
const artifact_LoanTreasurey = require('../anza/src/artifacts/LoanTreasurey.sol/LoanTreasurey.json');
const artifact_LoanCollateralVault = require('../anza/src/artifacts/CollateralVault.sol/CollateralVault.json');
const artifact_LibLoanContractInterest = require('../anza/src/artifacts/LibLoanContract.sol/LibLoanContractInterest.json');
const artifact_LibLoanContractSigning = require('../anza/src/artifacts/LibLoanContract.sol/LibLoanContractSigning.json');
const artifact_LibLoanContractRoles = require('../anza/src/artifacts/LibLoanContractConstants.sol/LibLoanContractRoles.json');
const artifact_DemoToken = require("../anza/src/artifacts/DemoToken.sol/DemoToken.json");


async function deploy() {
    const wallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
    const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");

    // const priv_key = process.env.PRIVATE_KEY;
    // const infura_api_key = process.env.INFURA_SEPOLIA_KEY

    // const wallet = new ethers.Wallet(priv_key);
    // const provider = new ethers.providers.InfuraProvider("sepolia", infura_api_key);

    const signer = wallet.connect(provider);

    // Deploy AnzaToken
    if (provider.connection.url === 'http://127.0.0.1:8545') {
        const demoToken = new ethers.ContractFactory(
            artifact_DemoToken.abi,
            artifact_DemoToken.bytecode,
            signer
        );
        const DemoToken = await demoToken.deploy();
        await DemoToken.deployed();
        console.log(`\n\tDemoToken successfully deployed to ${DemoToken.address}`);
    }

    // Deploy LibLoanContractRoles
    const libLoanContractRoles = new ethers.ContractFactory(
        artifact_LibLoanContractRoles.abi,
        artifact_LibLoanContractRoles.bytecode,
        signer
    );
    const LibLoanContractRoles = await libLoanContractRoles.deploy();
    await LibLoanContractRoles.deployed();
    console.log(`\n\tLibLoanContractRoles successfully deployed to ${LibLoanContractRoles.address}`);

    // Deploy LibLoanContractInterest
    const libLoanContractInterest = new ethers.ContractFactory(
        artifact_LibLoanContractInterest.abi,
        artifact_LibLoanContractInterest.bytecode,
        signer
    );
    const LibLoanContractInterest = await libLoanContractInterest.deploy();
    await LibLoanContractInterest.deployed();
    console.log(`\tLibLoanContractInterest successfully deployed to ${LibLoanContractInterest.address}`);

    // Deploy LibLoanContractSigning
    const libLoanContractSigning = new ethers.ContractFactory(
        artifact_LibLoanContractSigning.abi,
        artifact_LibLoanContractSigning.bytecode,
        signer
    );
    const LibLoanContractSigning = await libLoanContractSigning.deploy();
    await LibLoanContractSigning.deployed();
    console.log(`\tLibLoanContractSigning successfully deployed to ${LibLoanContractSigning.address}`);


    // Deploy AnzaToken
    const anzaToken = new ethers.ContractFactory(
        artifact_AnzaToken.abi,
        artifact_AnzaToken.bytecode,
        signer
    );
    const AnzaToken = await anzaToken.deploy();
    await AnzaToken.deployed();
    console.log(`\tAnzaToken successfully deployed to ${AnzaToken.address}`);

    // Deploy LoanContract
    const LoanContract_bytecode = artifact_LoanContract.bytecode.object;
    let linkedBytecode = LoanContract_bytecode;
    let linkReferences = artifact_LoanContract.bytecode.linkReferences["contracts/libraries/LibLoanContract.sol"]["LibLoanContractInterest"];
    for (const { start, length } of linkReferences) {
        linkedBytecode =
            LoanContract_bytecode.substr(0, 2 + start * 2) +
            LibLoanContractInterest.address.substr(2) +
            LoanContract_bytecode.substr(2 + (start + length) * 2);
    }

    const loanContract = new ethers.ContractFactory(
        artifact_LoanContract.abi,
        linkedBytecode,
        signer,
    );
    const LoanContract = await loanContract.deploy();
    await LoanContract.deployed();
    console.log(`\tLoanContract successfully deployed to ${LoanContract.address}`);

    // Deploy LoanTreasurey
    const LoanTreasurey_bytecode = artifact_LoanTreasurey.bytecode.object;
    linkedBytecode = LoanTreasurey_bytecode;
    linkReferences = artifact_LoanTreasurey.bytecode.linkReferences["contracts/libraries/LibLoanContract.sol"]["LibLoanContractInterest"];
    for (const { start, length } of linkReferences) {
        linkedBytecode =
            LoanTreasurey_bytecode.substr(0, 2 + start * 2) +
            LibLoanContractInterest.address.substr(2) +
            LoanTreasurey_bytecode.substr(2 + (start + length) * 2);
    }

    const loanTreasurey = new ethers.ContractFactory(
        artifact_LoanTreasurey.abi,
        linkedBytecode,
        signer
    );
    const LoanTreasurey = await loanTreasurey.deploy();
    await LoanTreasurey.deployed();
    console.log(`\tLoanTreasurey successfully deployed to ${LoanTreasurey.address}`);

    // Deploy CollateralVault
    const loanCollateralVaultFactory = new ethers.ContractFactory(
        artifact_LoanCollateralVault.abi,
        artifact_LoanCollateralVault.bytecode,
        signer
    );
    const CollateralVault = await loanCollateralVaultFactory.deploy(AnzaToken.address);
    await CollateralVault.deployed();
    console.log(`\tLoanCollateralVault successfully deployed to ${CollateralVault.address}\n`);

    // Get access control roles
    const role_loan_contract = await LibLoanContractRoles.LOAN_CONTRACT()
    const role_treasurer = await LibLoanContractRoles.TREASURER()

    // AnzaToken access control
    await (await AnzaToken.grantRole(role_loan_contract, LoanContract.address)).wait();
    await (await AnzaToken.grantRole(role_treasurer, LoanTreasurey.address)).wait();

    assert(await AnzaToken.hasRole(role_loan_contract, LoanContract.address), "AnzaToken :: loancontract ac incorrect");
    assert(await AnzaToken.hasRole(role_treasurer, LoanTreasurey.address), "AnzaToken :: treasurer ac incorrect");

    // LoanContract access control
    await (await LoanContract.setAnzaToken(AnzaToken.address)).wait();
    await (await LoanContract.setLoanTreasurer(LoanTreasurey.address)).wait();
    await (await LoanContract.setCollateralVault(CollateralVault.address)).wait();

    assert((await LoanContract.anzaToken()) === AnzaToken.address, "LoanContract :: anzatoken addr incorrect");
    assert((await LoanContract.loanTreasurer()) === LoanTreasurey.address, "LoanContract :: treasurer addr incorrect");
    assert((await LoanContract.collateralVault()) === CollateralVault.address, "LoanContract :: collateralvault addr incorrect");

    assert(await LoanContract.hasRole(role_treasurer, LoanTreasurey.address), "LoanContract :: treasurer ac incorrect");

    // LoanTreasurey access control
    await (await LoanTreasurey.setAnzaToken(AnzaToken.address)).wait();
    await (await LoanTreasurey.setLoanContract(LoanContract.address)).wait();
    await (await LoanTreasurey.setCollateralVault(CollateralVault.address)).wait();

    assert((await LoanTreasurey.anzaToken()) === AnzaToken.address, "LoanTreasurey :: anzatoken addr incorrect");
    assert((await LoanTreasurey.loanContract()) === LoanContract.address, "LoanTreasurey :: loancontract addr incorrect");
    assert((await LoanTreasurey.collateralVault()) === CollateralVault.address, "LoanTreasurey :: collateralvault addr incorrect");

    assert(await LoanTreasurey.hasRole(role_loan_contract, LoanContract.address), "LoanTreasurey :: loancontract ac incorrect");

    // CollateralVault access control
    await (await CollateralVault.setLoanContract(LoanContract.address)).wait();
    await (await CollateralVault.grantRole(role_treasurer, LoanTreasurey.address)).wait();

    assert((await CollateralVault.anzaToken()), AnzaToken.address, "AnzaToken :: anzatoken addr incorrect");
    assert((await CollateralVault.loanContract()), LoanContract.address, "CollateralVault :: loancontract addr incorrect");

    assert(await CollateralVault.hasRole(role_loan_contract, LoanContract.address), "CollateralVault :: loancontract ac incorrect");
    assert(await CollateralVault.hasRole(role_treasurer, LoanTreasurey.address), "CollateralVault :: treasurer ac incorrect");
}

deploy();