import {ethers} from "hardhat";
import {Staking} from "../types/staking";

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '';

async function main() {
  const [account] = await ethers.getSigners();

  console.log(`Unstake: contract=${STAKING_CONTRACT_ADDRESS}, account=${account.address}`);
  console.log("Account balance", (await account.getBalance()).toString());

  const StakingContractFactory = await ethers.getContractFactory("Staking");
  let stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as Staking;
  stakingContract = stakingContract.connect(account);

  const tx = await stakingContract.unstake()
  const receipt = await tx.wait();

  console.log("Unstaked", tx.hash, receipt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
