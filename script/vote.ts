import { ethers, network } from "hardhat";
import * as fs from "fs";
import {
    VOTING_PERIOD,
    developmentChains,
    proposalsFile,
} from "../utils/helper-hardhat-config";
import { moveBlocks } from "../utils/move-blocks";

const index = 0;

async function main(proposalIndex: number) {
    const proposals = JSON.parse(fs.readFileSync(proposalsFile, "utf8"));
    const proposalId = proposals[network.config.chainId!][proposalIndex];

    // 0 = Agains, 1 = For, 2 = Abstain
    const voteWay = 1;
    const reason = "because.";
    const governor = await ethers.getContract("AnzaGovernance");
    const voteTxResponse = await governor.castVoteWithReason(
        proposalId,
        voteWay,
        reason
    );

    await voteTxResponse.wait(1);

    if (developmentChains.includes(network.name)) {
        await moveBlocks(VOTING_PERIOD + 1);
    }

    console.log("Voted! Ready to go!!!");
}

main(index)
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
