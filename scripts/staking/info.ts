import {ethers} from "hardhat";
import {SXNode} from "../../types/SXNode";
require("dotenv").config();

const SXNODE_CONTRACT_ADDRESS = process.env.SXNODE_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';

async function main() {
  console.log("Check current contract information");

  const [deployer] = await ethers.getSigners();

  const SXNodeContractFactory = await ethers.getContractFactory("SXNode");
  let sxNodeContract = await SXNodeContractFactory.attach(SXNODE_CONTRACT_ADDRESS) as SXNode;
  sxNodeContract = sxNodeContract.connect(deployer);

  const validators = await sxNodeContract.getValidators()
  console.log('validators: ', validators)
  const outcome = await sxNodeContract.getOutcome()
  console.log('outcome: ', outcome)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
