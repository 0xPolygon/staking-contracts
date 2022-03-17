import {ethers} from "hardhat";
import {Staking} from "../types/Staking";

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '';

async function main() {
  console.log("Check current contract information");

  const StakingContractFactory = await ethers.getContractFactory("Staking");
  const stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as Staking;

  const [stakedAmount, validators, minimumNumValidators, maximumNumValidators] = await Promise.all([
    stakingContract.stakedAmount(),
    stakingContract.validators(),
    stakingContract.minimumNumValidators(),
    stakingContract.maximumNumValidators(),
  ])

  console.log(`Total staked amount: ${stakedAmount.toString()}`)
  console.log('Minimum number of validators', minimumNumValidators);
  console.log('Maximum number of validators', maximumNumValidators);
  console.log('Current validators list', validators);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
