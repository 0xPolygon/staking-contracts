import {ethers} from "hardhat";
import {Staking} from "../types/Staking";

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '';

async function main() {
  console.log("Check current contract information");

  const StakingContractFactory = await ethers.getContractFactory("Staking");
  const stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as Staking;

  const [stakedAmount, validators] = await Promise.all([
    stakingContract.stakedAmount(),
    stakingContract.validators(),
  ])

  console.log(`Total staked amount: ${stakedAmount.toString()}`)
  console.log('Current Validators', validators);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
