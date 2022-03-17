import {ethers} from "hardhat";

async function main() {
  const MinValidatorCount = 1;
  //Max uint32
	const MaxValidatorCount = 4294967295;

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const StakingContractFactory = await ethers.getContractFactory("Staking");

  const stakingContract = await StakingContractFactory.deploy(MinValidatorCount, MaxValidatorCount);

  console.log("Contract address:", stakingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
