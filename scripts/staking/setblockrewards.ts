import {ethers} from "hardhat";
import {BigNumber} from "ethers";
import {SXPoS} from "../../types/SXPoS";
require("dotenv").config();

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';
const VALIDATOR_REWARD = process.env.VALIDATOR_REWARD ?? "100000000000000000";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Set staking BlockRewards contract and block reward amount");

  console.log("Setting contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  let stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as SXPoS;
  stakingContract = stakingContract.connect(deployer);
  
  const setBlockRewardTx = await stakingContract.setBlockReward(BigNumber.from(VALIDATOR_REWARD))
  const setBlockRewardTxReceipt = await setBlockRewardTx.wait()
  console.log("txHash", setBlockRewardTx.hash)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
