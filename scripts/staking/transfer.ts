import { ethers } from "hardhat";

const SXNODE_CONTRACT_ADDRESS = process.env.SXNODE_CONTRACT_ADDRESS ?? "0x0000000000000000000000000000000000001001";
const STAKE_AMOUNT = ethers.utils.parseEther("1");

async function main() {
  const [account] = await ethers.getSigners();

  console.log(
    "Transfer value to contracts",
    "from",
    account.address,
    "to",
    SXNODE_CONTRACT_ADDRESS
  );
  console.log("Account balance:", (await account.getBalance()).toString());

  const tx = await account.sendTransaction({
    from: account.address,
    to: SXNODE_CONTRACT_ADDRESS,
    value: STAKE_AMOUNT,
    nonce: await account.getTransactionCount(),
    gasLimit: "0x100000",
    gasPrice: await account.getGasPrice(),
  });
  const receipt = await tx.wait();

  console.log("receipt", receipt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
