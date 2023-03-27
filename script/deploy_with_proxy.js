const { ethers, upgrades, artifacts } = require("hardhat");

async function main() {
    const libLoanContractFactoryOfficers = await deployLibrary("LibLoanContractFactoryOfficers");
    const Dispatcher = await getLinkedContractFactory("Dispatcher", {
        LibLoanContractFactoryOfficers: libLoanContractFactoryOfficers.address,
    });
    let dispatcher = await upgrades.deployProxy(Dispatcher, { kind: "transparent" });
    await dispatcher.deployed();

    console.log("Dispatcher deployed to: ", dispatcher.address);

    const LoanContractFactory = await ethers.getContractFactory("LoanContractFactory");
    const loanContractFactory = await LoanContractFactory.deploy(dispatcher.address);
    await loanContractFactory.deployed()

    console.log("admin: ", await loanContractFactory.admin());
    await loanContractFactory.testFunc();

    const libLoanContractFactoryOfficersV2 = await deployLibrary("LibLoanContractFactoryOfficersV2");
    const DispatcherV2 = await getLinkedContractFactory("DispatcherV2", {
        LibLoanContractFactoryOfficersV2: libLoanContractFactoryOfficersV2.address,
    });
    dispatcher = await upgrades.upgradeProxy(dispatcher.address, DispatcherV2, { kind: "transparent" });
    await dispatcher.deployed();

    console.log("Box upgraded");

    console.log("admin: ", await loanContractFactory.admin());
    await loanContractFactory.testFunc();
}

function linkBytecode(artifact, libraries) {
    let bytecode = artifact.bytecode;
    for (const [, fileReferences] of Object.entries(artifact.linkReferences)) {
        for (const [libName, fixups] of Object.entries(fileReferences)) {
            const addr = libraries[libName];
            if (addr === undefined) {
                continue;
            }
            for (const fixup of fixups) {
                bytecode =
                    bytecode.substr(0, 2 + fixup.start * 2) +
                    addr.substr(2) +
                    bytecode.substr(2 + (fixup.start + fixup.length) * 2);
            }
        }
    }
    return bytecode;
}

async function deployLibrary(libraryName) {
    const Library = await ethers.getContractFactory(libraryName);
    const library = await Library.deploy();
    await library.deployed();
    return library;
}

async function getLinkedContractFactory(contractName, libraries) {
    const cArtifact = await artifacts.readArtifact(contractName);
    const linkedBytecode = linkBytecode(cArtifact, libraries);
    const ContractFactory = await ethers.getContractFactory(cArtifact.abi, linkedBytecode);
    return ContractFactory;
}

main();
