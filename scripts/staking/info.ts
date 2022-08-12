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
  const signer = await sxNodeContract.getSigner()
  console.log('signer: ', signer)
  const sigBytes = await sxNodeContract.sigBytes()
  console.log('sigBytes: ', sigBytes)
  const hashedReport = await sxNodeContract.hashedReport()
  console.log('hashedReport: ', hashedReport)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
