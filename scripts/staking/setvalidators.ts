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
  
  const setValidatorsTx = await stakingContract.setValidators(['0x30b3eCF398eEB21D038Ba6a9221BD40255B4fE04',
  '0xF016C0F8854bcE260261b41150173FB071c9E3F6',
  '0x74615232119ab0eBA508BdBc910FAF7bdD8196d6',
  '0xa24ef1E3C22D2Ab3F20D75f809Fc2D3cf47eF42c','0xe58E04DD6a8314155CcaFeF0c708899733579c64'])
  const setBlockRewardTxReceipt = await setValidatorsTx.wait()
  console.log("txHash", setValidatorsTx.hash)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });