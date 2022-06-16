import {ethers} from "hardhat";
import {SXPoS} from "../types/SXPoS";
require("dotenv").config();

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';

async function main() {
  console.log("Check current contract information");

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  const stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as SXPoS;

  const [stakedAmount, validators, minimumNumValidators, maximumNumValidators, blockReward] = await Promise.all([
    stakingContract.stakedAmount(),
    stakingContract.validators(),
    stakingContract.minimumNumValidators(),
    stakingContract.maximumNumValidators(),
    stakingContract.getBlockReward(),
  ])

  console.log(`Total staked amount: ${stakedAmount.toString()}`)
  console.log('Minimum number of validators', minimumNumValidators.toNumber());
  console.log('Maximum number of validators', maximumNumValidators.toNumber());
  console.log('Current validators list', validators);
  console.log('Current epoch block reward', blockReward);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
