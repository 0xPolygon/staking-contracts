import {ethers} from "hardhat";
import {SXPoS} from "../../types/SXPoS";
require("dotenv").config();

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';

async function main() {
  console.log("Set Staking epoch size");

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  const stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as SXPoS;

  const setEpochSizeTx = await stakingContract.setEpochSize(20)
  const setEpochSizeTxReceipt = await setEpochSizeTx.wait()
  console.log(`setEpochSizeTx hash: ${setEpochSizeTx.hash}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
