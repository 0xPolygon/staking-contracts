import { ethers } from "hardhat";
import { Staking } from "../types/Staking";

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? "";

async function main() {
  console.log("Check current contract information");

  const stakingContract = (await ethers.getContractAt(
    "Staking",
    STAKING_CONTRACT_ADDRESS
  )) as Staking;

  const [
    stakedAmount,
    validators,
    blsPublicKeys,
    minimumNumValidators,
    maximumNumValidators,
  ] = await Promise.all([
    stakingContract.stakedAmount(),
    stakingContract.validators(),
    stakingContract.validatorBLSPublicKeys(),
    stakingContract.minimumNumValidators(),
    stakingContract.maximumNumValidators(),
  ]);

  console.log(`Total staked amount: ${stakedAmount.toString()}`);
  console.log("Minimum number of validators", minimumNumValidators.toNumber());
  console.log("Maximum number of validators", maximumNumValidators.toNumber());
  console.log("Current validators list", validators);
  console.log("BLS Public Keys", blsPublicKeys);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
