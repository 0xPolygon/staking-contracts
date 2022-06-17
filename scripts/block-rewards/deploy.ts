import {ethers, upgrades} from "hardhat";
import {BigNumber} from "ethers";

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const BlockRewardsContractFactory = await ethers.getContractFactory("BlockRewards");
 
  const blockRewardsContract = await BlockRewardsContractFactory.deploy(STAKING_CONTRACT_ADDRESS);
  console.log("Contract address:", blockRewardsContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
