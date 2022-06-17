import {ethers, upgrades} from "hardhat";
import {BigNumber} from "ethers";

const VALIDATOR_REWARD = process.env.VALIDATOR_REWARD ?? "100000000000000000"; // 0.1 ether
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

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  const staking = await upgrades.deployProxy(StakingContractFactory, [BigNumber.from(VALIDATOR_REWARD), MIN_VALIDATOR_COUNT, MAX_VALIDATOR_COUNT], {
    kind: "uups",
    initializer: "initialize",
  });

  console.log("Contract address:", staking.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
