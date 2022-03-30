import {ethers} from "hardhat";

const MIN_VALIDATOR_COUNT = process.env.MIN_VALIDATOR_COUNT ?? 1;
const MAX_VALIDATOR_COUNT = process.env.MAX_VALIDATOR_COUNT ?? Number.MAX_SAFE_INTEGER - 1;

async function main() {
  const [deployer] = await ethers.getSigners();

  if (MIN_VALIDATOR_COUNT > MAX_VALIDATOR_COUNT) {
    console.log("MIN_VALIDATOR_COUNT can not be greater than MAX_VALIDATOR_COUNT")
    return
  }

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const StakingContractFactory = await ethers.getContractFactory("Staking");

  const stakingContract = await StakingContractFactory.deploy(MIN_VALIDATOR_COUNT, MAX_VALIDATOR_COUNT);

  console.log("Contract address:", stakingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
