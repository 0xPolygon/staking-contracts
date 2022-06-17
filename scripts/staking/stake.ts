import {ethers} from "hardhat";
import {Staking} from "../../types/Staking";
require("dotenv").config();

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';
const STAKE_AMOUNT = ethers.utils.parseEther("1")

async function main() {
  const [deployer, val1, val2, val3, val4] = await ethers.getSigners();

  console.log(`Stake: address=${STAKING_CONTRACT_ADDRESS}, account=${val4.address}`);
  console.log(`Account balance: ${(await val4.getBalance()).toString()}`);

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  let stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as Staking;
  stakingContract = stakingContract.connect(val1);

  const tx = await stakingContract.stake({ value: STAKE_AMOUNT })
  const receipt = await tx.wait();

  console.log("Staked", tx.hash, receipt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
