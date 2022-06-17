import {ethers} from "hardhat";
import {SXPoS} from "../../types/SXPoS";
require("dotenv").config();

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';
const BLOCK_REWARDS_CONTRACT_ADDRESS = process.env.BLOCK_REWARDS_CONTRACT_ADDRESS;

async function main() {
  console.log("Set staking BlockRewards contract and block reward amount");

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  const stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as SXPoS;

  const setBlockRewardsContractTx = await stakingContract.setBlockRewardsContract(BLOCK_REWARDS_CONTRACT_ADDRESS!)
  const setBlockRewardsContractTxReceipt = await setBlockRewardsContractTx.wait()
  console.log(`setBlockRewardsContractTx hash: ${setBlockRewardsContractTx.hash}`)

  /*
  const setBlockRewardTx = await stakingContract.setBlockReward("100000000000000000")
  const setBlockRewardTxReceipt = await setBlockRewardTx.wait()
  console.log(`setBlockRewardTx hash: ${setBlockRewardTx.hash}`)
  */
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
