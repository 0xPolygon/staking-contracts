import {ethers} from "hardhat";
import {Staking} from "../../types/Staking";
require("dotenv").config();

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';
const STAKE_AMOUNT = ethers.utils.parseEther("1")

async function main() {
  const signers = await ethers.getSigners()

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  let stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as Staking;
  
  for (let i = 1; i < signers.length; i++) {
    console.log(`Stake: address=${STAKING_CONTRACT_ADDRESS}, account=${signers[i].address}`);
    console.log(`Account balance: ${(await signers[i].getBalance()).toString()}`);
    stakingContract = stakingContract.connect(signers[i]);
    const tx = await stakingContract.stake({ value: STAKE_AMOUNT })
    const receipt = await tx.wait();
    console.log("txHash", tx.hash);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
