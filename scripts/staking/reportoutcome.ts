import {ethers} from "hardhat";
import {SXNode} from "../../types/SXNode";
require("dotenv").config();


const SXNODE_CONTRACT_ADDRESS = process.env.SXNODE_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';
const VALIDATOR_REWARD = process.env.VALIDATOR_REWARD ?? "100000000000000000";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Set staking BlockRewards contract and block reward amount");

  console.log("Setting contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const StakingContractFactory = await ethers.getContractFactory("SXNode");
  let stakingContract = await StakingContractFactory.attach(SXNODE_CONTRACT_ADDRESS) as SXNode;
  stakingContract = stakingContract.connect(deployer);
  
  const reportOutcomeTx = await stakingContract.reportOutcome(4)
  const reportOutcomeTxReceipt = await reportOutcomeTx.wait()
  console.log("txHash", reportOutcomeTx.hash)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });