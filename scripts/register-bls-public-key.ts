import { ethers } from "hardhat";
import { Staking } from "../types/Staking";

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? "";
const BLS_PUBLIC_KEY = process.env.BLS_PUBLIC_KEY ?? "";

async function main() {
  const [account] = await ethers.getSigners();

  console.log(
    `Register BLS Public Key: address=${STAKING_CONTRACT_ADDRESS}, account=${account.address}, key=${BLS_PUBLIC_KEY}`
  );
  console.log(`Account balance: ${(await account.getBalance()).toString()}`);

  const stakingContract = (await ethers.getContractAt(
    "Staking",
    STAKING_CONTRACT_ADDRESS,
    account
  )) as Staking;

  const tx = await stakingContract.registerBLSPublicKey(BLS_PUBLIC_KEY);
  const receipt = await tx.wait();

  console.log("Registered", tx.hash, receipt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
